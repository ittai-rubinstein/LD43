import 'dart:html';
import 'dart:math';

const bool DEBUG_TOC = false;

class TextOnCanvas {
    // The canvas on which we will be drawing the text
    CanvasElement canvas;  
    // The 2d drawing context
    CanvasRenderingContext2D ctx;

    String Title;

    // The highest point visible in the screen:
    static const num Y_MIN_POS = 70;
    // The leftmost point visible in the screen:
    static const int X_MIN_POS = 7;
    // The converse values depend upon the window size (which may be dynamic?)
    num GetMaxYPos(){
        return canvas.height - Y_MIN_POS;
    }
    num GetMaxXPos(){
        return canvas.width - X_MIN_POS - 2;
    }
    // How far down we need to jump between lines:
    static const int LINE_HEIGHT = 20;

    // The position of the current line being edited. These values will be updated as the prints goes on.
    num YPosCurrLine = Y_MIN_POS;
    num XPosCurrPrint = X_MIN_POS;

    // This is the height of the newest line in the code. Is currently set to the bottom of the screen.
    num NewestLineYPos;

    // The width of a character. Measured in a horani manner.
    static const num CHARACTER_WIDTH = 10.8369140625;

    TextOnCanvas(String canvas_name, String title){
        // Ask the html for the canvas of the console, on which we will print everything:
        canvas = querySelector('#$canvas_name');
        // Generate a 2d drawing context:
        ctx = canvas.getContext('2d');

        // Save Title for printing.
        Title = title;

        // Debug prints
        if (DEBUG_TOC) {
            print("Canvas name: $canvas_name");
            print(canvas);
            print(ctx);
        }

        // Prevent annoying stretching, by making everything absolute size:
        canvas.width = canvas.clientWidth;
        canvas.height = canvas.clientHeight;

        // Initialize the printing head to the botoom of the screen. Later, this should be changed.
        NewestLineYPos = Y_MIN_POS;
    }

    void PrintTitle(){
        // Set print parameters
        ctx.font = "28px Monospace";
        ctx.fillStyle = "Grey";
        // Compute the width of the title
        num TitleWidth = ctx.measureText(Title).width;
        ctx.fillText(Title, (canvas.width - TitleWidth) / 2, 40);
    }


    /**
     * Ends the line currently being printed, and returns the carrage
     */
    void GoToNewLine(){
        XPosCurrPrint = X_MIN_POS;
        YPosCurrLine += LINE_HEIGHT;
    }

    /**
     * Sets the text color to the requested value.
     */
    void setFillStyle(String new_style){
        ctx.fillStyle = new_style;
    }

    // Prints a string that is not expected to require a new line
    // Updates the XPosCurrPrint Accordingly
    void PrintStringToScreenSimple(String message){
        ctx.font = "18px monospace";
        ctx.fillText(message, XPosCurrPrint, YPosCurrLine);
        XPosCurrPrint += ctx.measureText(message).width;    
    }

    void ClearScreen(){
        // Save the fillStyle for later
        String fillStyle = ctx.fillStyle;
        // Reset the screen size
        canvas.width = canvas.clientWidth;
        canvas.height = canvas.clientHeight;
        // Clear the screen
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        // Print the title
        PrintTitle();
        // Set the font and color
        setFillStyle(fillStyle);
        ctx.font = "18px monospace";
    }

    /**
     * Prints a String to the console, separating it into several lines as necessary.
     */
    void PrintStringToScreenMultipleLines(String message){
        while (message.endsWith("\n")) {
            message = message.substring(0, message.length-1);
        }
        for (var i = 0; i < message.length; i++) {
            var current_character = message[i];
            if (current_character == "\n") {
                XPosCurrPrint = X_MIN_POS;
                YPosCurrLine += LINE_HEIGHT;
            } else{
                if (XPosCurrPrint + CHARACTER_WIDTH <= GetMaxXPos()) {
                    ctx.fillText(current_character, XPosCurrPrint, YPosCurrLine);
                    XPosCurrPrint += CHARACTER_WIDTH;
                } else{
                    YPosCurrLine += LINE_HEIGHT;
                    XPosCurrPrint = X_MIN_POS;
                    ctx.fillText(current_character, XPosCurrPrint, YPosCurrLine);
                    XPosCurrPrint += CHARACTER_WIDTH;
                }
            }
        }
    }

    /**
     * Sets the printing head to start printing so that it will finish printing at the requested height
     */
    void SetPrintingHead(num NumLines){
        // Compute the Y axis of the first line to be printed:
        num BaseYPos = NewestLineYPos - ((NumLines - 1) * LINE_HEIGHT);
        // Set the printing head to the start of the print:
        XPosCurrPrint = X_MIN_POS;
        YPosCurrLine = BaseYPos;
    }

    // Computes the number of characters that fit in one line of the console
    int NumCharactersPerLine(){
        return (canvas.width / CHARACTER_WIDTH).floor();
    }

    // Computes the number of lines necessary for writing a string
    int NumLinesForString(String message){
        if (message == "") {
            return 0;
        }
        while (message.endsWith("\n")) {
            message = message.substring(0, message.length-1);
        }
        int result = 1;
        num temp_x = X_MIN_POS;
        for (var i = 0; i < message.length; i++) {
            var c = message[i];
            if (c == "\n") {
                temp_x = X_MIN_POS;
                result += 1;
            } else{
                if (temp_x + CHARACTER_WIDTH <= GetMaxXPos()) {
                    temp_x += CHARACTER_WIDTH;
                } else{
                    temp_x = X_MIN_POS + CHARACTER_WIDTH;
                    result += 1;
                }
            }
        }
        if (DEBUG_TOC) {
            print("Estimate that it will take $result lines to print ${message}");
            print("${message.length - message.replaceAll("\n", "").length}");
        }
        // return (message.length.toDouble() / NumCharactersPerLine()).ceil();
        return result;
    }
}