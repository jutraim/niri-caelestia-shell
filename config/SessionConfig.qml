import Quickshell.Io

JsonObject {
    property bool enabled: true
    property int dragThreshold: 30
    property Sizes sizes: Sizes {}

    component Sizes: JsonObject {
        property int button: 80
    }
}
