# セットアップ手順

## 1. Flutter のインストール

https://docs.flutter.dev/get-started/install/windows/mobile

上記URLからFlutter SDKをダウンロードしてインストールしてください。
インストール後、`flutter doctor` を実行して環境確認。

## 2. Firebase プロジェクト作成

1. https://console.firebase.google.com/ にアクセス
2. 「プロジェクトを追加」をクリック
3. プロジェクト名を入力（例: hotel-cleaning-app）
4. 以下のサービスを有効化：
   - **Firestore Database**（テストモードで開始）
   - **Storage**（テストモードで開始）

## 3. FlutterFire CLIでFirebase設定

```powershell
# FlutterFire CLIをインストール
dart pub global activate flutterfire_cli

# プロジェクトディレクトリに移動
cd C:\Users\royal\Documents\claude\hotel_cleaning_app

# パッケージのインストール
flutter pub get

# Firebase設定ファイルを自動生成（lib/firebase_options.dart が更新される）
flutterfire configure
```

`flutterfire configure` 実行後、自動的に `lib/firebase_options.dart` が正しい値で更新されます。

## 4. Android設定（Androidでビルドする場合）

`android/app/build.gradle` に以下を追加：
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

## 5. アプリ起動

```powershell
flutter run
```

## 初期PINコード

| ロール | 初期PIN |
|--------|---------|
| 清掃スタッフ | 1111 |
| 点検者 | 2222 |
| 管理者 | 3333 |

管理者ログイン後、マスター管理 → PINコード管理から変更できます。

## Firestoreのデータ構造

```
/config/pins
  - staff_pin: string
  - inspector_pin: string
  - admin_pin: string

/floors/{floorId}
  - name: string
  - order: int
  - createdAt: timestamp

/rooms/{roomId}
  - floorId: string
  - floorName: string
  - number: string
  - status: string (未着手/清掃中/点検待ち/点検OK/販売可)
  - updatedBy: string?
  - updatedAt: timestamp?
  - sendbackComment: string?

/defect_reports/{reportId}
  - roomId: string
  - roomNumber: string
  - floorName: string
  - location: string
  - photoUrls: array<string>
  - registeredBy: string
  - registeredAt: timestamp
  - status: string (未対応/対応中/修繕待ち/修繕完了)
  - completionPhotoUrl: string?
  - completedAt: timestamp?
  - notes: string?

/lost_items/{itemId}
  - roomId: string
  - roomNumber: string
  - floorName: string
  - photoUrl: string
  - registeredBy: string
  - registeredAt: timestamp
  - date: string (YYYY-MM-DD)
  - status: string (保管中/返却済み/廃棄済み)
  - completedAt: timestamp?
  - description: string?
```
