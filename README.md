# SLMTransformMaker3D
([Go here](https://github.com/llerussell/SLMTransformMaker) for single 2D plane calibrations)

Matlab program to calculate the transformation required to map 2P imaging space onto SLM space, allowing correct targets of ROIs.

## Procedure
* <i>Optional: Calibrate uncaging galvos using zero order spot. This will ensure the centre of SLM space is the centre of 2P imaging space.</i>
* Burn multiple spots onto fluorescent slide (simultaneously or sequentially)
* take a 2P volume stack of the burnt slide
* Register the SLM targets image and the 2P burnt spot image
* Use the saved transform when making all future [SLM phase masks](https://github.com/llerussell/SLMPhaseMaskMaker3D)

<center><img src="http://i.imgur.com/GnmjOWt.jpg" width="300"></center>

## User interface
![img](https://i.imgur.com/6HOrFoc.png)
