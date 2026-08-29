import swaggerAutogen from 'swagger-autogen';

const doc = {
    info: {
        title: 'GigConnect Backend API',
        description: 'Auto-generated Swagger documentation for GigConnect services',
    },
    host: 'localhost:5000', // Apka port number
    schemes: ['http', 'https'],
    securityDefinitions: {
        bearerAuth: {
            type: 'apiKey',
            in: 'header',
            name: 'Authorization',
            description: 'Enter JWT token with Bearer prefix (e.g., Bearer <token>)'
        }
    }
};

const outputFile = './swagger-output.json';
const routesFiles = [
    './routes/auth-routes.js',
    './routes/booking-routes.js',
    './routes/worker-routes.js',
    './routes/service-routes.js',
    './routes/payment-routes.js',
    './routes/review-routes.js',
    './routes/home-routes.js',
    './routes/ai-routes.js'
];

swaggerAutogen()(outputFile, routesFiles, doc);