# ANAPay2Zaim

これは ANA Pay の利用通知メールを受信し、Zaim へ利用履歴を記録するバッチです。

## 概要

このアプリケーションは、ANA Pay の利用通知メールを IMAP4 で取得し、Zaim API を使用して家計簿に記録します。

## 機能

- ANA Pay の利用通知メールから取引情報を抽出
- merchant_mapping.yml に基づいたマーチャント名の変換とカテゴリ分類
  - 完全一致しない場合、前方一致でマーチャント情報を検索
- Zaim への自動記録
- 重複処理防止（message-id を使用）

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

   - IMAP サーバーの情報
   - メールアカウントの認証情報
   - Zaim API の認証情報

5. Zaim API の OAuth 認証トークンを取得します：

   ```bash
   ruby auth/token_acquirer.rb
   ```

6. Zaim のジャンル情報を取得します：
   ```bash
   ruby auth/genre_retriever.rb
   ```

## 使い方

```bash
ruby app.rb
```

## 構成

- `lib/email_fetcher.rb`: メール取得のロジック
- `lib/zaim_api_client.rb`: Zaim API との通信ロジック
- `lib/anapay_to_zaim.rb`: ANA Pay メールを Zaim に登録するロジック
- `auth/token_acquirer.rb`: Zaim OAuth トークン取得スクリプト
- `auth/genre_retriever.rb`: Zaim ジャンル情報取得スクリプト
- `auth/account_retriever.rb`: Zaim 口座情報取得スクリプト
- `app.rb`: メインアプリケーション
- `.env`: 環境変数（git 管理外）
- `zaim_tokens.json`: Zaim アクセストークン（git 管理外）
- `zaim_genres.json`: Zaim ジャンル情報（git 管理外）
- `zaim_accounts.json`: Zaim 口座情報（git 管理外）

## テスト

テストスイートは RSpec を使用しています：

```bash
bundle exec rspec
```

テストは以下のコンポーネントをカバーしています：

- ANA Pay メールの取得と解析
- Zaim API との通信
- メールデータの Zaim への登録
