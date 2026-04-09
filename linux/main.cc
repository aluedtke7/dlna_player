#include "my_application.h"
//#include <hid_listener/hid_listener_plugin.h>
#include <locale.h>
#include <stdlib.h>

int main(int argc, char** argv) {
  setenv("LC_NUMERIC", "C", 1);
  setenv("LC_ALL", "C", 1);
  setlocale(LC_NUMERIC, "C");
//  HidListener listener;
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
