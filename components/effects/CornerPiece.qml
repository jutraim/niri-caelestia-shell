import QtQuick

Item {
    id: cornerShape
    width: 48
    height: 48

    property color color: "red"
    property int radius: 16
    property int orientation: 0 // 0=TOP_LEFT, 1=TOP_RIGHT, 2=BOTTOM_LEFT, 3=BOTTOM_RIGHT
    property bool invertH: false
    property bool invertV: false

    Canvas {
        anchors.fill: parent
        // antialiasing: true // Add this line
        onPaint: {
            const ctx = getContext("2d");
            const w = parent.width;
            const h = parent.height;
            const r = Math.max(0, Math.min(cornerShape.radius, Math.min(w, h)));
            const k = 0.55228475;

            ctx.reset();
            ctx.save();

            ctx.translate(cornerShape.invertH ? w : 0, cornerShape.invertV ? h : 0);
            ctx.scale(cornerShape.invertH ? -1 : 1, cornerShape.invertV ? -1 : 1);

            // draw full rect
            ctx.beginPath();
            ctx.rect(0, 0, w, h);
            ctx.closePath();

            // draw quarter-circle as negative cutout
            ctx.beginPath();

            switch (cornerShape.orientation) {
            case 0 // TOP_LEFT
            :
                ctx.moveTo(0, r);
                ctx.lineTo(0, 0);
                ctx.lineTo(r, 0);
                ctx.bezierCurveTo(r * (1 - k), 0, 0, r * (1 - k), 0, r);
                break;
            case 1 // TOP_RIGHT
            :
                ctx.moveTo(w - r, 0);
                ctx.lineTo(w, 0);
                ctx.lineTo(w, r);
                ctx.bezierCurveTo(w, r * (1 - k), w - r * (1 - k), 0, w - r, 0);
                break;
            case 2 // BOTTOM_LEFT
            :
                ctx.moveTo(0, h - r);
                ctx.lineTo(0, h);
                ctx.lineTo(r, h);
                ctx.bezierCurveTo(r * (1 - k), h, 0, h - r * (1 - k), 0, h - r);
                break;
            case 3 // BOTTOM_RIGHT
            :
                ctx.moveTo(w - r, h);
                ctx.lineTo(w, h);
                ctx.lineTo(w, h - r);
                ctx.bezierCurveTo(w, h - r * (1 - k), w - r * (1 - k), h, w - r, h);
                break;
            }

            ctx.closePath();
            ctx.clip("evenodd"); // <-- subtracts the corner curve from the rectangle

            // fill remaining shape
            ctx.fillStyle = cornerShape.color;
            ctx.fillRect(0, 0, w, h);

            ctx.restore();
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
    }
}
