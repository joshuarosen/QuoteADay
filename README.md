# Quote a Day

Check it out on [itch.io](https://mrmeowmurs.itch.io/quote-a-day).

This project was a way for me to play around and get familiar with the various aspects of the Playdate SDK. As I'm new to both the Playdate SDK and Lua, there is messy code in this repo. There are bad practices. There are probably even some bugs (gasp).

But in the spirit of contributing to the Playdate community, I thought I would share it here on the off chance that my prototype-y code ends up being useful to someone (please reach out on [Bluesky](https://bsky.app/profile/joshuarosen.bsky.social) if that's the case, I'd love to hear from you!)

I've had a blast developing on the Playdate - the SDK docs are well-written, and I've found so many good resources just from lurking on the [dev forums](https://devforum.play.date/) and in the fan-run [Discord server](https://discord.com/invite/zFKagQ2). I really love how open and helpful the community is, and there's so much creativity on display with every Playdate project that I come across.

## Some random learnings

1. The Playdate is not a very powerful device, so trying to fade out text was un-surprisingly taxing on the framerate. Check out the `fade_image_patterns` file to see the pre-computed masks at discrete alpha thresholds that I used to fade out "chunks" of the text, which runs a lot better than dynamically generating a mask at many different alpha levels over time. I was afraid that it would make the fade really choppy, but it actually ended up looking quite good with the right chunk size.

2. `playdate.ui.gridview` is very helpful for making a scrollable list of items. The SDK docs have some helpful examples for how to use it as a "list" (with a single column) rather than as a "grid". I ended up using it in both the `schedule_screen` and the `category_dialog` for selecting a category per weekday.

3. The synth in `intro_jingle_player` was fun to play around with :)
