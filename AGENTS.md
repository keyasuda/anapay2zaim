# ANAPay2Zaim

これは ANA Pay の利用通知メールを受信し、Zaim へ利用履歴を記録するバッチです。

## 処理の流れ

- メールを取得(IMAP4)
  - 過去 1 週間分を取得、未処理のもののみを処理(message-id で判断)
- 店舗名から加盟店名(日本語表記), ジャンル, カテゴリをデータソース(YAML ファイル)から引く
- Zaim に POST /v2/home/money/payment
- 書き込み済みログを残す

## 技術スタック

- Ruby 3.4.5
- mail gem, net/imap (メール処理)
- net/http (API コール)
- dotenv (メールサーバ/API credentials)

## 参考資料

- 利用通知メール samples/payinfo.eml
- Zaim API samples/zaim_api.txt
