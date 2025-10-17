# ANAPay2Zaim

これは ANA Pay の利用通知メールを受信し、Zaim へ利用履歴を記録するバッチです。

## 概要

このアプリケーションは、ANA Pay の利用通知メールを IMAP4 で取得し、Zaim API を使用して家計簿に記録します。

## セットアップ

1. Ruby 3.4.5 が必要です。
2. 依存関係をインストールします：
   ```bash
   bundle install
   ```

3. 環境変数を設定します：
   ```bash
   cp .env.example .env
   ```
   
4. `.env` ファイルを編集し、以下の情報を入力してください：
   - IMAPサーバーの情報
   - メールアカウントの認証情報
   - Zaim APIの認証情報

5. Zaim APIのOAuth認証トークンを取得します：
   ```bash
   ruby auth/token_acquirer.rb
   ```

6. Zaimのジャンル情報を取得します：
   ```bash
   ruby auth/genre_retriever.rb
   ```

## 使い方

```bash
ruby app.rb
```

## 構成

- `lib/email_fetcher.rb`: メール取得のロジック
- `lib/zaim_api_client.rb`: Zaim APIとの通信ロジック
- `lib/anapay_to_zaim.rb`: ANA PayメールをZaimに登録するロジック
- `auth/token_acquirer.rb`: Zaim OAuthトークン取得スクリプト
- `auth/genre_retriever.rb`: Zaimジャンル情報取得スクリプト
- `app.rb`: メインアプリケーション
- `.env`: 環境変数（git管理外）
- `zaim_tokens.json`: Zaimアクセストークン（git管理外）
- `zaim_genres.json`: Zaimジャンル情報（git管理外）

## テスト

テストスイートはRSpecを使用しています：

```bash
bundle exec rspec
```

テストは以下のコンポーネントをカバーしています：
- ANA Payメールの取得と解析
- Zaim APIとの通信
- メールデータのZaimへの登録