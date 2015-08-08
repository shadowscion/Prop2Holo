
A quick STool I made (by request of Karbine) that allows you to turn a selection of entities into a ready-made hologram script for expression2.

You can find the tool under the wire "Tools" category.

<p align="center">
<a href="http://www.youtube.com/watch?feature=player_embedded&v=z9x_82OIx-I
" target="_blank"><img src="http://img.youtube.com/vi/z9x_82OIx-I/0.jpg" 
alt="Watch on Youtube!" title="Watch on Youtube!" width="560" height="315"/></a>
</p>


Features:
- Supports visclip (must be the workshop version uploaded by Wrex)
- Supports bodygroups and skins
- Copy output to clipboard
- Open output in a new tab in the e2 editor

Guide:
- Look at a prop and click to add it to (or remove it from) the selection
- Look at a prop (this prop will become the center of the contraption) and right click to output
- In the output code, you can change the scale of the entire contraption at the top
- If you wish to edit holograms after they have spawned, you must put the code in the "InitPostSpawn" block at the bottom, like so:
```
elseif (CoreStatus == "InitPostSpawn") {
    CoreStatus = "RunThisCode"
    
    holoRemove(5)
    holoScale(10, vec(25, 25, 25))
    
    runOnTick(0)
}
```

- If you wish to manipulate holograms in real time, you must put the code in the "RunThisCode" block at the bottom, like so:
```
elseif (CoreStatus == "RunThisCode") {
    # You can use tickClk or clk here, just be sure to set your timers up in the InitPostSpawn block
    holoPos(1, holoEntity(1):pos() + vec(10, 0, 0))
    holoAng(1, ang(curtime()*100, 0, 0))
}
```

