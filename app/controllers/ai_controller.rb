require 'net/http'
require 'uri'
require 'json'
require 'erb'
require 'ostruct'

class AiController < ApplicationController
  def chat
    @nana = Nana.find_by(id: params[:nana_id]) if params[:nana_id].present?
    
    if @nana.nil?
      @ai_response = "⚠️ ナナのデータが見つかりません。"
      return
    end

    if params[:user_input].present?
      current_question = params[:user_input]

      prompt_instruction = <<~TEXT
        あなたはユーザーのメッセージから「感情」を分析し、その感情を元に「架空の可愛い生き物」を1体生み出すプロバイダーです。
        必ず以下のルールとJSONフォーマット【のみ】を出力してください。余計な挨拶や解説、Markdown記号(```jsonなど)は含めないでください。

        【出力フォーマット（JSON）】
        {
          "analysis": "■感情分析\\n喜び：8ポイント\\n不安：1ポイント\\n期待：9ポイント\\n安心：6ポイント\\n切なさ：0ポイント",
          "creature_name": "ルミナス",
          "creature_desc": "光をあつめて優しく輝く、小さな妖精のような生き物です。",
          "image_keyword": "cute glowing fantasy creature, pink gold, soft fluffy, full body, white background"
        }

        ※image_keywordは、生き物の外見を表す短い英語のキーワード（カンマ区切り）にしてください。
      TEXT

      # --- 履歴を「最新3件（往復）」だけに制限してAIに渡す処理 ---
      full_history = @nana.ai_response.presence || ""
      # 過去のやり取り（「あなた:〜」「AI:〜」のペア）を分割
      blocks = full_history.split("\n\n").reject(&:blank?)
      
      # 直近の最大6ブロック（ユーザー3件＋AI3件＝3往復分）だけを取得
      recent_blocks = blocks.last(6)
      recent_history_text = recent_blocks.join("\n\n")

      # Gemini APIへの安全なリクエスト作成
      api_key = ENV["GEMINI_API_KEY"]
      uri = URI::HTTPS.build(
        host: 'generativelanguage.googleapis.com',
        path: '/v1beta/models/gemini-2.5-flash:generateContent',
        query: 'key=' + api_key
      )
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
      
      # 過去3件分の履歴 + 今回の入力のみをGeminiに送信（これで超軽量化！）
      user_payload = "#{prompt_instruction}\n\n【これまでの会話（直近のみ）】\n#{recent_history_text}\n\nユーザーの入力:\n#{current_question}"

      request.body = {
        contents: [
          {
            role: "user",
            parts: [{ text: user_payload }]
          }
        ],
        generationConfig: {
          response_mime_type: "application/json"
        }
      }.to_json

      response = http.request(request)
      result = JSON.parse(response.body)

      if result["candidates"] && result["candidates"][0]["content"]
        raw_ai_text = result["candidates"][0]["content"]["parts"][0]["text"]
        
        keyword = "cute fantasy creature"
        formatted_text = ""

        begin
          parsed = JSON.parse(raw_ai_text)
          analysis = parsed["analysis"]
          c_name = parsed["creature_name"]
          c_desc = parsed["creature_desc"]
          
          raw_keyword = parsed["image_keyword"].to_s.gsub(/[^a-zA-Z0-9\s,]/, '')
          keyword = raw_keyword.presence || "cute fantasy creature"

          formatted_text = "#{analysis}\n\n■生き物\n名前：#{c_name}\n\n説明：#{c_desc}"
        rescue JSON::ParserError
          formatted_text = "【分析結果】\n#{raw_ai_text}"
          keyword = "cute fantasy creature"
        end

        encoded_prompt = ERB::Util.url_encode(keyword)
        random_seed = rand(10000..99999)
        
        img_uri = URI::HTTPS.build(
          host: 'image.pollinations.ai',
          path: '/prompt/' + encoded_prompt,
          query: "seed=#{random_seed}&width=400&height=400&nologo=true"
        )
        image_url = img_uri.to_s

        formatted_ai_response = "#{formatted_text}\n\n[IMG_URL:#{image_url}]"

        # 全履歴自体はDBに保存しておく（カレンダー用）
        updated_history = "#{full_history}あなた: #{current_question}\n\nAI: #{formatted_ai_response}\n\n"
        @nana.update(ai_response: updated_history)

        # 画面表示用にも最新3往復＋今回の会話だけをセット
        all_blocks = updated_history.split("\n\n").reject(&:blank?)
        @ai_response = all_blocks.last(8).join("\n\n") # 直近4往復分（今回分＋過去3件）

      elsif result["error"]
        @ai_response = (full_history) + "\n⚠️ APIエラー: #{result['error']['message']}\n"
      else
        @ai_response = (full_history) + "\n⚠️ レスポンスの取得に失敗しました。\n"
      end

    else
      if @nana.ai_response.blank?
        initial_greeting = "AI: こんにちは！#{@nana.name}さん。今日の気持ちや出来事を教えてくださいね！\n\n"
        @nana.update(ai_response: initial_greeting)
        @ai_response = initial_greeting
      else
        # 初期表示時も最新3往復のみ画面に出す
        blocks = (@nana.ai_response || "").split("\n\n").reject(&:blank?)
        @ai_response = blocks.last(6).join("\n\n")
      end
    end
  end
  
  # カレンダー画面を表示するアクション
  def calendar
    @nana = Nana.find(params[:id])
    @logs = parse_history_to_logs(@nana.ai_response || "")
  end

  private

  # 履歴テキストから画像URLや生き物の名前を抽出する処理
  def parse_history_to_logs(history_text)
    logs = []
    blocks = history_text.split(/(?=あなた: )/).reject(&:blank?)

    blocks.each do |block|
      img_url = block.match(/\[IMG_URL:(.*?)\]/)&.captures&.first
      creature_name = block.match(/名前：(.*?)$/)&.captures&.first
      
      # Hash ではなく OpenStruct で渡すことで simple_calendar が読み込めるようにする
      logs << OpenStruct.new(
        date: @nana.updated_at.to_date,
        content: block.gsub(/\[IMG_URL:.*?\]/, ''),
        image_url: img_url,
        creature_name: creature_name
      )
    end

    # 履歴が空の場合でもエラーにならないよう初期表示データを入れる
    if logs.empty?
      logs << OpenStruct.new(
        date: @nana.updated_at.to_date,
        content: "会話履歴がありません",
        image_url: nil,
        creature_name: nil
      )
    end

    logs
  end
end