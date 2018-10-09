Devices.jl is not intended to be a graphical editor for CAD files. However, on occasion it
is very useful to see the resulting patterns and measure dimensions, even if no edits are
intended. When used with the [Juno IDE](http://www.junolab.org), Devices.jl will show
graphical previews of cells in the Plots pane. There is nothing you need to do to enable
this behavior besides using Juno.

Coordinates of the mouse cursor are displayed in the top-left corner. You can zoom using the
scroll wheel.

To reset the view to the default zoom and translation, press '/'. You may need to click
within the view to ensure keyboard events are caught.

To measure, click once within the view. (Clicking and dragging will just pan the view.) A
red line will appear and follow your mouse cursor. The distance between where you clicked
originally and the current mouse location will be displayed. Click again to exit
measurement. If you're trying to measure a very small distance relative to the bounds of
the displayed cell, you may get better results if you display a smaller cell containing the
region of interest, if possible. The distance measurements are only accurate up to the
fidelity with which the Cairo graphics library renders the SVG file.
