import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
   if let dbUrlEnv = Environment.get("DATABASE_URL"), var postgresConfig = PostgresConfiguration(url: dbUrlEnv) {
        postgresConfig.tlsConfiguration = .makeClientConfiguration()
        postgresConfig.tlsConfiguration?.certificateVerification = .none
        app.databases.use(.postgres(
            configuration: postgresConfig
        ), as: .psql)
    } else {
    // if let dbUrlEnv = Environment.get("DATABASE_URL"){
    //     dbUrl = dbUrlEnv
    //     try app.databases.use(.postgres(url: dbUrl), as: .psql)
    //     print("DB_URL: \(dbUrl)")
    // } else {
        app.databases.use(.postgres(
            hostname: Environment.get("DB_HOSTNAME")!,
            port: Environment.get("DB_PORT").flatMap(Int.init(_:))!,
            username: Environment.get("DB_USERNAME")!,
            password: Environment.get("DB_PASSWORD")!,
            database: Environment.get("DB_NAME")!),
            as: .psql)

        // app.databases.use(.postgres()
    }

     let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)

    // Only add this if you want to enable the default per-route logging
    let routeLogging = RouteLoggingMiddleware(logLevel: .info)

    // Add the default error middleware
    let error = ErrorMiddleware.default(environment: app.environment)
    // Clear any existing middleware.
    app.middleware = .init()
    app.middleware.use(cors)
    app.middleware.use(routeLogging)
    app.middleware.use(error)
    
    app.logger.logLevel = .debug

    app.migrations.add(CreateTodo())

    try app.autoMigrate().wait()

    // register routes
    try routes(app)
}
