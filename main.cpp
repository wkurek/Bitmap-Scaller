#include <stdio.h>
#include <allegro5/allegro.h>
#include <allegro5/allegro_image.h>
#include <allegro5/allegro_primitives.h>
#include <allegro5/allegro_font.h>

#define MAX_BITMAP_PATH_LENGTH 24
#define SCALED_BITMAP_FILENAME "scaled_image.bmp"

#define DISPLAY_TITLE  "Bitmap-Scaler"

#define DISPLAY_HEIGHT 536
#define DISPLAY_WIDTH 904
#define CONSOLE_HEIGHT 30
#define CANVAS_HEIGHT 500
#define CANVAS_WIDTH 900
#define MARGIN 6
#define CONSOLE_BITMAP_SIZE_CONTROL_MARGIN_LEFT 700


extern "C" int func(char* path, int outputWidth, int outputHeight);

ALLEGRO_DISPLAY *display = NULL;
ALLEGRO_BITMAP *bitmap = NULL;

int bitmapWidth = 0, bitmapHeight = 0; //width and height of imported bitmap
char* inputBitmapPath = "privacy.bmp"; //path to input file

struct Point {
    float x, y;

    Point(float x, float y) {
        this->x = x;
        this->y = y;
    }
};

Point getBitmapStartCords(int width, int height) {
    float x = (CANVAS_WIDTH - width)/2 + MARGIN;
    float y = (CANVAS_HEIGHT - height)/2 + CONSOLE_HEIGHT + 2*MARGIN;

    return Point(x, y);
}

void drawControls() {
    al_clear_to_color(al_map_rgb(242,242,242));
    al_draw_filled_rectangle(MARGIN, CONSOLE_HEIGHT + 2*MARGIN, DISPLAY_WIDTH - MARGIN,
        DISPLAY_HEIGHT - MARGIN, al_map_rgb(225,225,225));
    al_flip_display();
}


void refreshScaledBitmap() {
    drawControls();

    bitmap = al_load_bitmap(SCALED_BITMAP_FILENAME);
    if(bitmap == NULL) return;

    Point bitmapStartPoint = getBitmapStartCords(al_get_bitmap_width(bitmap), al_get_bitmap_height(bitmap));
    al_draw_bitmap(bitmap, bitmapStartPoint.x, bitmapStartPoint.y, 1);
    al_flip_display();
}

void loadNewBitmap() {
    bitmap = al_load_bitmap(inputBitmapPath);

       bitmapWidth = al_get_bitmap_width(bitmap);
       bitmapHeight = al_get_bitmap_height(bitmap);

   func(inputBitmapPath, bitmapWidth, bitmapHeight);
   refreshScaledBitmap();
}

double getBitmapLoadTime(int bitmapWidth, int bitmapHeight) {
    double pixelsNumber = (bitmapWidth * bitmapHeight);
    return pixelsNumber/1000000*9.6 + 0.114;
}

int main(int argc, char **argv) {

    //Init allegro library
   if(!al_init() || !al_init_image_addon()) {
      fprintf(stderr, "Failed to initialize allegro!\n");
      return -1;
   }

   al_init_font_addon();
   ALLEGRO_FONT *font8 = al_create_builtin_font();

   //Create and set up display
   display = al_create_display(DISPLAY_WIDTH, DISPLAY_HEIGHT);
   al_set_window_title(display, DISPLAY_TITLE);
   if(!display) {
      fprintf(stderr, "failed to create display!\n");
      return -1;
   }

   //Set up event queues
   ALLEGRO_EVENT_QUEUE *eventQueue;
   eventQueue = al_create_event_queue();

   al_install_keyboard();
   al_install_mouse();

   al_register_event_source(eventQueue, al_get_keyboard_event_source());
   al_register_event_source(eventQueue, al_get_display_event_source(display));
   al_register_event_source(eventQueue, al_get_mouse_event_source());

   //Set up initial layout
   drawControls();
   loadNewBitmap();


   //Loop varables
   bool running = true, bitmapSizeChanged = false;
   double time = al_get_time();

   ALLEGRO_USTR *bitmapPath = al_ustr_new("");

   while(running) {
        ALLEGRO_EVENT event;

        if(!al_is_event_queue_empty(eventQueue)) {
            al_wait_for_event(eventQueue, &event);

            switch(event.type) {
                case ALLEGRO_EVENT_DISPLAY_CLOSE: {
                    running = false;
                    break;
                }
                case ALLEGRO_EVENT_MOUSE_BUTTON_DOWN: {
                    //TODO: check for clicking label or OK button
                    break;
                }
                case ALLEGRO_EVENT_KEY_CHAR: {
                    if(event.keyboard.unichar >= 32) {
                        //TODO: Deal with user file path input

                        al_ustr_append_chr(bitmapPath, event.keyboard.unichar);
                        al_draw_ustr(font8, al_map_rgb(0,255, 0), 10, 10, 0, bitmapPath);
                        al_flip_display();
                    } else {
                        //Deal with on arrow button click actions

                        if(al_get_time() > time + 0.01) {
                            if (event.keyboard.keycode == ALLEGRO_KEY_LEFT
                                && bitmapWidth > 10) {

                                bitmapWidth-=4;
                                bitmapSizeChanged = true;
                            } else if (event.keyboard.keycode == ALLEGRO_KEY_RIGHT
                                && bitmapWidth < CANVAS_WIDTH) {

                                bitmapWidth+=4;
                                bitmapSizeChanged = true;
                            } else if (event.keyboard.keycode == ALLEGRO_KEY_UP
                                && bitmapHeight < CANVAS_HEIGHT) {

                                bitmapHeight+=4;
                                bitmapSizeChanged = true;
                            } else if (event.keyboard.keycode == ALLEGRO_KEY_DOWN
                                && bitmapHeight > 10) {

                                bitmapHeight-=4;
                                bitmapSizeChanged = true;
                            }

                            time = al_get_time();
                        }
                    }

                }
            }

            al_rest(0.001);

        } else if(bitmapSizeChanged){
            func(inputBitmapPath, bitmapWidth, bitmapHeight);
            refreshScaledBitmap();
            bitmapSizeChanged = false;

            al_rest(getBitmapLoadTime(bitmapWidth, bitmapHeight)); //wait until bitmap is loaded
        }
   }

   if(bitmap != NULL) al_destroy_bitmap(bitmap);
   al_destroy_display(display);


   return 0;
}
