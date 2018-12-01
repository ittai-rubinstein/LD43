import 'dart:html';
import 'dart:collection'; 
import 'dart:io';

CanvasElement ConsoleCanvas;  
CanvasRenderingContext2D ConsoleCTX;

void PrintKey(KeyboardEvent ke){
    print('${ke.key}');
    print('${ke.charCode}');
}

class Keyboard {  
  HashMap<int, num> _keys = new HashMap<int, num>();

  Keyboard() {
    window.onKeyDown.listen((KeyboardEvent event) {
      _keys.putIfAbsent(event.keyCode, () => event.timeStamp);
    });

    window.onKeyUp.listen((KeyboardEvent event) {
      _keys.remove(event.keyCode);
    });
  }

  bool isPressed(int keyCode) => _keys.containsKey(keyCode);
}

// void MyOnClick(){
//     print('I was clicked');
// }
void main() {
    print('Hello world');
    ConsoleCanvas = querySelector("#Console");
    print("$ConsoleCanvas");
    ConsoleCTX = ConsoleCanvas.getContext('2d');
    window.onKeyDown.listen(PrintKey);
    // ConsoleCTX.fillStyle = "#ffffff";
    // ConsoleCTX.fillRect(0, 0, ConsoleCanvas.width, ConsoleCanvas.height);
    // var keyboard = Keyboard();
    // while(true){
    //     sleep(const Duration(seconds: 1));
    //     print('Keys being pressed: ${keyboard._keys}');
    // }
    // var stream = KeyEvent.keyPressEvent.forTarget(ConsoleCanvas);
    // stream.listen((keyEvent) => window.console.log('KeyPress event detected ${keyEvent.charCode}'));
}


