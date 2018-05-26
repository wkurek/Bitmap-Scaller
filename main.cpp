#include <stdio.h>
#include <allegro5/allegro.h>
#include <allegro5/allegro_image.h>
#include <allegro5/allegro_primitives.h>

extern "C" int func(char* path, int outputWidth, int outputHeight);

const int DISPLAY_HEIGHT = 536;
const int DISPLAY_WIDTH = 904;
const int CONSOLE_HEIGHT = 30;
const int CANVAS_HEIGHT = 500;
const int CANVAS_WIDTH = 900;
const int MARGIN = 6;

struct Point {
    float x, y;

    Point(float x, float y) {
        this->x = x;
        this->y = y;
    }
};

Point getBitmapStartCords(int width, int height) {
    return Point((CANVAS_WIDTH - width)/2 + MARGIN, (CANVAS_HEIGHT - height)/2 + CONSOLE_HEIGHT + 2*MARGIN);
}

int main(int argc, char **argv) {


   ALLEGRO_DISPLAY *display = NULL;

   if(!al_init()) {
      fprintf(stderr, "failed to initialize allegro!\n");
      return -1;
   }

   al_init_image_addon();


   func("/home/wojtek/Documents/ARKO/Bitmap-Scaller/privacy.bmp", 500, 300);



   display = al_create_display(DISPLAY_WIDTH, DISPLAY_HEIGHT);
   al_set_window_title(display, "Title example");
   if(!display) {
      fprintf(stderr, "failed to create display!\n");
      return -1;
   }



   al_clear_to_color(al_map_rgb(242,242,242));

   al_draw_filled_rectangle(MARGIN, CONSOLE_HEIGHT + 2*MARGIN, DISPLAY_WIDTH - MARGIN, DISPLAY_HEIGHT - MARGIN, al_map_rgb(225,225,225));


   ALLEGRO_BITMAP *bitmap = al_load_bitmap("/home/wojtek/Documents/ARKO/Bitmap-Scaller/scaled_image.bmp");
   Point bitmapStartPoint = getBitmapStartCords(500, 300);
   al_draw_bitmap(bitmap, bitmapStartPoint.x, bitmapStartPoint.y, 1);


   al_flip_display();
   al_rest(15.0);

   al_destroy_bitmap(bitmap);
   al_destroy_display(display);

   return 0;
}
