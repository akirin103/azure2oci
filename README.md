# azure2oci
本リポジトリは、`Microsoft Azure`(以下Azure)と`Oracle Cloud Inflastructure`(以下OCI)を使用したプライベートクラウド構築の検証を行うためのものです。インフラ構築には`Terraform`を使用します。

<br />

## 構築するインフラ一覧
|  Cloud  |  リソース名  |  概要  |
| ---- | ---- | ---- |
|  Azure  |  ExpressRoute  |  プライベート接続を作成  |
|    |   vNet  |  仮想ネットワーク  |
|    |   VirtualNetworkGateway  |  ExpressRoute用のゲートウェイ  |
|    |   VirtualMachine  |  動作確認用の仮想マシン  |
|  OCI  |  FastConnect  |  プライベート接続を作成  |
|    |   仮想クラウド・ネットワーク  |  仮想ネットワーク  |
|    |   動的ルーティングゲートウェイ  |  FastConnect用のゲートウェイ  |
|    |   インスタンス  |  動作確認用の仮想マシン  |

※ 代表的なものだけ列挙しています。

<br />

![Azure と Oracle Cloud Infrastructure 間の直接相互接続をセットアップする](https://user-images.githubusercontent.com/47296773/169279637-5a0b401b-6b47-4be3-9807-1c881ac0efc6.png)

<br />

## 構築方法

1. Terraformをインストールします。

2. Azure CLIの設定をします。

3. OCI CLIの設定をします。

4. プロジェクトのルートディレクトリ下に`terraform.tfvars`という名前のファイルを作成します。

5. 3で設定したコンパートメントIDを4で作成したファイルに下記のように記載します。  

    ```
    compartment_ocid = "ocid........"
    ```

6. 下記のコマンドを順に実行します。

    ```sh
    # 初期化処理
    $ terraform init

    # 実行計画作成(エラーを吐いた場合はメッセージに従って問題を解決してください)
    $ terraform plan

    # リソース作成(エラーを吐いた場合はメッセージに従って問題を解決してください)
    $ terraform apply --auto-approve
    ```

<br />

## 検証
- tracerouteとifconfigコマンドは`cloud-init`でインストール済み  
インストールのログは`/var/log/cloud-init-output.log`を参照  

- OCI側の動作確認
    ```sh
    # OCIのbastion(パブリックサーバ)にSSH接続
    $ ssh ubuntu@<bastionのpublic-ip>

    # プライベートサーバと疎通確認
    ubuntu@azure2oci-public-instance:~$ ping <private-ip>

    # 多段SSHでプライベートサーバにSSH接続
    $ ssh -o ProxyCommand='ssh -W %h:%p ubuntu@<bastionのpublic-ip>' ubuntu@<プライベートサーバのprivate-ip>
    ```

- Azure側の動作確認
    ```sh
    # Azureのbastion(パブリックサーバ)にSSH接続
    $ ssh azureuser@<bastionのpublic-ip>

    # プライベートサーバと疎通確認
    azureuser@azure2oci-bastion-vm:~$ ping <private-ip>

    # 多段SSHでプライベートサーバにSSH接続
    $ ssh -o ProxyCommand='ssh -W %h:%p azureuser@<bastionのpublic-ip>' azureuser@<プライベートサーバのprivate-ip>
    ```

- AzureとOCI間のプライベート接続動作確認
    ```
    # OCI → Azureの接続確認
    # 多段SSHでOCI側のプライベートサーバにSSH接続
    $ ssh -o ProxyCommand='ssh -W %h:%p ubuntu@<bastionのpublic-ip>' ubuntu@<プライベートサーバのprivate-ip>
    # 疎通確認
    $ ping <Azure側のプライベートサーバのprivate-ip>

    # Azure → OCI の接続確認
    # 多段SSHでAzure側のプライベートサーバにSSH接続
    $ ssh -o ProxyCommand='ssh -W %h:%p azureuser@<bastionのpublic-ip>' azureuser@<プライベートサーバのprivate-ip>
    # 疎通確認
    $ ping <OCI側のプライベートサーバのprivate-ip>
    ```
## 参考

- [Azure と Oracle Cloud Infrastructure 間の直接相互接続をセットアップする](https://docs.microsoft.com/ja-jp/azure/virtual-machines/workloads/oracle/configure-azure-oci-networking)  

- [踏み台サーバ経由の多段SSH接続をローカル端末の秘密鍵のみで実施する](https://dev.classmethod.jp/articles/bastion-multi-stage-ssh-only-local-pem/)

- [ルート テーブルの作成、変更、削除](https://learn.microsoft.com/ja-jp/azure/virtual-network/manage-route-table)
