class Users::SessionsController < Devise::SessionsController
  def create
    email = params[:user][:email]
    
    # メールアドレスでユーザーを検索し、無ければパスワード自動生成で新規作成
    self.resource = User.find_or_create_by(email: email)

    # パスワードなしでそのままログイン状態にする
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  end
end
