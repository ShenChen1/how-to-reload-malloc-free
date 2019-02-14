# 发送patchset:

(1)
先生成要提交的几个patch(这里生成了3个，-n是生成序列信息如1/3，最早的提交放在最前面):
```
$git format-patch -s -3 -n
```

发送patchset：
```
$git send-email --compose ./*.patch
```
这里使用--compose增加一个[PATCH 0/m]作为summary，输入命令后编辑器打开，此时要添写
subject, body作为[PATCH 0/m]的内容(也就是此时为手写的summary)。

此时后面发送的每个patch都是对第一条的回复，后面的第一个patch的In-Reply-To都是第一
条的Message-Id。而不是对前一条的回复。这是因为git send-email默认情况下使用
--no-chain-reply-to参数：
```
--[no-]chain-reply-to
If this is set, each email will be sent as a reply to the previous email sent.
If disabled with "--no-chain-reply-to", all emails after the first will be sent as replies
to the first email sent. When using this, it is recommended that the first file given be an
overview of the entire patch series.Disabled by default, but the sendemail.
chainreplyto configuration variable can be used to enable it.
```

(2)
生成patch时也可以使用--cover-letter参数：
```
$git format-patch -3 -n --cover-letter
```
这会生成一个0000-cover-letter.patch文件：
```
--[no-]cover-letter
In addition to the patches, generate a cover letter file containing the shortlog
and the overall diffstat.You can fill in a description in the file before sending it out.
```
需要编辑0000-cover-letter.patch文件的subject和body，做为对这个patchset的介绍，
注意一定要先编辑再发送，否则git send-email不让发送
--cover-letter会自动生成diffstat信息，所以不需要添加--stat参数

然后发送patch，此时可以不用--compose参数：
```
$git send-email ./*.patch --to=xxx@gmail.com
```
