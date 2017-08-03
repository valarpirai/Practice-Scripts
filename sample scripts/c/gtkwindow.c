  #include <iostream.h>
  #include <gtk/gtk.h>

  int main(int argc, char* argv[])
  {

    gtk_init(&argc, &argv);

    GtkWidget *window, *button;

    window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    button = gtk_button_new_with_label("Push the button.");
gtk_container_add(GTK_CONTAINER(window), button);

	g_signal_connect(G_OBJECT(button), "button_press_event", G_CALLBACK(ClickCallback), NULL);
gtk_widget_show_all(window);

  gtk_main(); 
    return 0;
  }

 void ClickCallback(GtkWidget *widget, GdkEventButton *event, gpointer callback_data)
  {
    // show which button was clicked
    std::cerr << "button pressed: " << event->button << std::endl;
  }
