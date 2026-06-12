import "dotenv/config.js";
import express from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';

//Import Routes
import userRoutes from './routes/userRoutes.js';
import adminRoutes from "./routes/adminRoutes.js";
import profileRoutes from "./routes/profileRoutes.js";
import doctorRoutes from './routes/doctorRoutes.js';

const app = express();
app.use(bodyParser.json());
// THÊM DÒNG NÀY: Để Node.js đọc được dữ liệu từ Form HTML gửi lên
app.use(express.urlencoded({ extended: true })); 
app.use(cors({ origin: '*' }));

//Routes
app.get('/',(req,res) => {
    res.json({message: "Server API running"});
});
app.use('/api/doctors', doctorRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/auth', userRoutes);
app.use('/api/profile', profileRoutes);

app.use((req,res,next)=>{
    res.status(404).json({message: 'Endpoint not found'});
});

//Custom error handler
app.use((err,req,res,next)=>{
    console.error(err.stack);
    if(res.headersSent) return next(err);

    if(process.env.NODE_ENV === 'production'){
        return res.status(500).json({message: 'Something went wrong!'});
    }
    else return res.status(500).json({
        message: err.message,
        code: err.code,
        url: req.originalUrl,
        body: req.body,
        stack: err.stack
    });
});

//Start Server
const PORT = process.env.PORT || 3001;
app.listen(PORT, ()=>{
    console.log(`Server running on port ${PORT}`);
});
export default app;