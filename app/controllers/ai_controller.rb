require 'cgi'
require 'net/http'
require 'uri'
require 'json'
require 'erb'
require 'ostruct'

class AiController < ApplicationController
  before_action :authenticate_user!

  def chat
    # ログイン中のユーザー(current_user)に紐づくNanaを取得（無ければその人用に作成）
    @nana = current_user.nanas.first || current_user.nanas.create!(name: "なぎさ")

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

      full_history = @nana.ai_response.presence || ""
      blocks = full_history.split("\n\n").reject(&:blank?)
      
      recent_blocks = blocks.last(6)
      recent_history_text = recent_blocks.join("\n\n")

      api_key = ENV["GEMINI_API_KEY"] || ""
      uri = URI.parse("[https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#](https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#){api_key}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
      
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

        encoded_keyword = CGI.escape(keyword)
        random_seed = rand(10000..99999)
        image_url = "[https://image.pollinations.ai/prompt/#](https://image.pollinations.ai/prompt/#){encoded_keyword}?seed=#{random_seed}&width=400&height=400&nologo=true&model=flux"

        formatted_ai_response = "#{formatted_text}\n\n[IMG_URL:#{image_url}]"

        updated_history = "#{full_history}あなた: #{current_question}\n\nAI: #{formatted_ai_response}\n\n"
        @nana.update(ai_response: updated_history)

        all_blocks = updated_history.split("\n\n").reject(&:blank?)
        @ai_response = all_blocks.last(8).join("\n\n")

      elsif result["error"]
        @ai_response = "#{full_history}\n⚠️ APIエラー: #{result['error']['message']}\n"
      else
        @ai_response = "#{full_history}\n⚠️ レスポンスの取得に失敗しました。\n"
      end

    else
      if @nana.ai_response.blank?
        initial_greeting = "AI: こんにちは！#{@nana.name}さん。今日の気持ちや出来事を教えてくださいね！\n\n"
        @nana.update(ai_response: initial_greeting)
        @ai_response = initial_greeting
      else
        blocks = (@nana.ai_response || "").split("\n\n").reject(&:blank?)
        @ai_response = blocks.last(6).join("\n\n")
      end
    end
  end
  
  def calendar
    # 他人のカレンダーが見えないよう current_user から探す
    @nana = current_user.nanas.find(params[:id])
    @logs = parse_history_to_logs(@nana.ai_response || "")
  end

  private

  def parse_history_to_logs(history_text)
    logs = []
    blocks = history_text.split(/(?=あなた: )/).reject(&:blank?)

    blocks.each do |block|
      img_url = block.match(/\[IMG_URL:(.*?)\]/)&.captures&.first
      creature_name = block.match(/名前：(.*?)$/)&.captures&.first
      
      logs << OpenStruct.new(
        date: @nana.updated_at.to_date,
        content: block.gsub(/\[IMG_URL:.*?\]/, ''),
        image_url: img_url,
        creature_name: creature_name
      )
    end

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