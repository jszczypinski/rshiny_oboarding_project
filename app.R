# fmt: skip
box::use(
    shiny[shinyApp],
    lib/database[create_db_con],
    app_ui = ./ui,
    app_server = ./server
)

con <- create_db_con() # created once, at app startup

shinyApp(
    ui = app_ui$ui,
    server = function(input, output, session) {
        app_server$server(
            input = input,
            output = output,
            session = session,
            con = con # passed explicitly into server
        )
    }
)
