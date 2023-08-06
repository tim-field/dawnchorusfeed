# DawnChorusFeed

Build with
`mix escript.build`

that'll give you a dawnchoursfeed binary

`scp dawnchorusfeed tim@mohiohio.com:/var/www/dawn-chorus/`

interactive play with
`iex -S mix` ( use iex.bat on windows )

> iex(1)> DawnChorusFeed.create_feed('./example-audio','./example-images')

recompile with `recompile`

get new deps with
`mix deps.get`
