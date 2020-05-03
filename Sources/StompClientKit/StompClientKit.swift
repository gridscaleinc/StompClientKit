/**
 * StompClientKit is a framework library of Stomp Client, over websoket.
 *
 *  . Targeted Users
 *      Developers who want to use Stomp as a wire protocol to handle webcoket frames.
 *
 *  . Supported Stomp Versions
 *      1.0 up to 1.2
 *  .  Supported Swift and Xcode version
 *      This library was developed in the environment of Xcode11, Swift5.2. Use it for other versions at your own discretion.
 */
public struct StompClientKit {
    public let version = "1.0.0"
    public let supportedVersions = "1.0,1.1,1.2"
}

/**
 *   Supported Versions.
 *  StompClientKit supports STOMP versions from 1.0 to 1.2.
 */
public enum StompVersions: String {
    case VER1_0 = "1.0"
    case VER1_1 = "1.1"
    case VER1_2 = "1.2"
    case UNKNOWN = "?.?"
}


