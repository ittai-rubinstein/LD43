import 'dart:html';
import 'dart:math';

const bool DEBUG_TOC = true;

class TextOnCanvas {
    // The canvas on which we will be drawing the text
    CanvasElement canvas;  
    // The 2d drawing context
    CanvasRenderingContext2D ctx;

    // The highest point visible in the screen:
    static const num Y_MIN_POS = 20;
    // The leftmost point visible in the screen:
    static const int X_MIN_POS = 7;
    // The converse values depend upon the window size (which may be dynamic?)
    num GetMaxYPos(){
        return canvas.height - Y_MIN_POS;
    }
    num GetMaxXPos(){
        return canvas.width - X_MIN_POS;
    }
    // How far down we need to jump between lines:
    static const int LINE_HEIGHT = Y_MIN_POS;

    // The position of the current line being edited. These values will be updated as the prints goes on.
    num YPosCurrLine = Y_MIN_POS;
    num XPosCurrPrint = X_MIN_POS;

    // This is the height of the newest line in the code. Is currently set to the bottom of the screen.
    num NewestLineYPos;

    // The width of a character. Measured in a horani manner.
    static const num CHARACTER_WIDTH = 10.8369140625;

    TextOnCanvas(String canvas_name){
        // Ask the html for the canvas of the console, on which we will print everything:
        canvas = querySelector('#$canvas_name');
        // Generate a 2d drawing context:
        ctx = canvas.getContext('2d');

        // Debug prints
        print("Canvas name: $canvas_name");
        print(canvas);
        print(ctx);

        // Prevent annoying stretching, by making everything absolute size:
        canvas.width = canvas.clientWidth;
        canvas.height = canvas.clientHeight;

        // Initialize the printing head to the botoom of the screen. Later, this should be changed.
        NewestLineYPos = Y_MIN_POS;
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
        print(new_style);
        print(ctx.fillStyle);
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
        // Set the font and color
        setFillStyle(fillStyle);
        ctx.font = "18px monospace";
    }

    /**
     * Prints a String to the console, separating it into several lines as necessary.
     */
    void PrintStringToScreenMultipleLines(String message){
        // While we still have data to print:
        while (message.isNotEmpty) {
            // Check how many charcters can be printed on the current line.
            // If it contains no \n chars, then it is determined by the width of the screen.
            // If it does contain a \n char, then it is determined by the first of the two.
            num max_chars_curr_line = min(((GetMaxXPos() - XPosCurrPrint) / CHARACTER_WIDTH).floor(), 
                                            ((message.indexOf("\n") <= 0)?(1000000):(message.indexOf("\n") + 1)));
            // If all the data fits in one line, we print it, and don't go to a new line
            if (message.length <= max_chars_curr_line) {
                if (DEBUG_TOC) {
                    print('Printing $message to single line.');
                }
                PrintStringToScreenSimple(message);
                break;
            // Otherwise, we print what we can to this line, then jump to the next line, and remove what needs to be removed
            // from the data to be printed.
            } else {
                if (DEBUG_TOC) {
                    print('Printing ${message.substring(0,max_chars_curr_line)} to single line.');
                }
                PrintStringToScreenSimple(message.substring(0,max_chars_curr_line));
                GoToNewLine();
                message = message.substring(max_chars_curr_line);
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
        return (message.length.toDouble() / NumCharactersPerLine()).ceil();
    }
}