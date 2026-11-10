class ApplicationController < ActionController::Base
before_action :authenticate_user!

# ログインした直後に呼ばれる処理
def after_sign_in_path_for(resource)
  # ナナのデータを探し、もし1つも無ければ自動で作成する
  nana = Nana.first || Nana.create!(name: "なぎさ")

  # ナナのIDと一緒にトーク画面へ移動する
  "/ai?nana_id=#{nana.id}"
end
end