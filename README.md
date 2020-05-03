# Stomp Client Kit

StompClientKit is a framework library of Stomp Client, over websoket.   
[ Stomp ](https://stomp.github.io/)   
[ Starscream](https://github.com/daltoniam/Starscream)   

# Features

   . Targeted Users
       Developers who want to use Stomp as a wire protocol to handle webcoket frames.   
 
   . Supported Stomp Versions   
       1.0 up to 1.2
       
   .  Supported Swift and Xcode version   
       This library was developed in the environment of Xcode11, Swift5.2. Use it for other versions at your own discretion.

# Usage
## Import the framework

```
import StompClientKit
```
## Initialization client
```
var stompclient = StompClient(endpoint: "ws://abc.example.com/anywebsocket/endpoint")
stompclient.messageHandler = self.handleMessage
stompclient.startConnect ( onConnected:  {
  client in
  client.subscribe(to: "/awesome/topic")
})
```

## Handle Message
```
func handleMessage(frame: Frame)  {
    DispatchQueue.main.async {
        do {
             let dto = try JSONDecoder().decode(ContentDto.self, from: frame.body.data)
             self.content.message = dto.content
         } catch {
            // Deserialization error         
            print("Error occoured while decoding message body")
         }
                
    }
}
```

## Sending message
### Sending JSON Message
```
    let jsonString = JSONEncoder().encode(object)
    client.send(json: jsonString, to:"/app/sayhello", using:.utf8, conentType:"application/json")
```

### Sending Text Message
```
    let text = "hello!"
    client.send(text: text, to:"/app/sayhello", using:.utf8, conentType:"text/plain")
```

### Sending by Object conform to StompMessage Protocol
```
client.send(json: stompMsgObj, to:"/app/sayhello", using:.utf8, conentType:"application/json")

// Or

client.send(text: stompMsgObj, to:"/app/sayhello", using:.utf8, conentType:"text/plain")
```




