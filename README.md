
A quick STool I made (by request of Karbine) that allows you to turn a selection of entities into a ready-made hologram script for expression2.

You can find the tool under the wire "Tools" category.

Features:
- Supports visclip (must be the workshop version uploaded by Wrex)
- Copy output to clipboard
- Open output in a new tab in the e2 editor

Guide:
*1) Look at a prop and click to add it to (or remove it from) the selection
*2) Look at a prop (this prop will become the center of the contraption) and right click to output
*3) In the output code, you can change the scale of the entire contraption at the top
*4) If you wish to edit holograms after they have spawned, you must put the code in the "InitPostSpawn" block at the bottom, like so:
```
elseif (CoreStatus == "InitPostSpawn") {
    CoreStatus = "RunThisCode"
    
    holoRemove(5)
    holoScale(10, vec(25, 25, 25))
    
    runOnTick(0)
}
```

*5) If you wish to manipulate holograms in real time, you must put the code in the "RunThisCode" block at the bottom, like so:
```
elseif (CoreStatus == "RunThisCode") {
    # You can use tickClk or clk here, just be sure to set your timers up in the InitPostSpawn block
    holoPos(1, holoEntity(1):pos() + vec(10, 0, 0))
    holoAng(1, ang(curtime()*100, 0, 0))
}
```

