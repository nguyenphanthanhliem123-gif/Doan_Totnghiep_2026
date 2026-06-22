import "dotenv/config.js";
import express from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';
import { Server } from "socket.io";
import http from 'http';
import '../Backend_NodeJS/utils/cronJob.js';
import '../Backend_NodeJS/utils/cronJob24h.js';
import fileUpload from 'express-fileupload';
import path from 'path';
import { fileURLToPath } from 'url';

//Import Routes
import userRoutes from './routes/userRoutes.js';
import adminRoutes from "./routes/adminRoutes.js";
import profileRoutes from "./routes/profileRoutes.js";
import healthRecordRoutes from "./routes/healthRecordRoutes.js";
import doctorRoutes from './routes/doctorRoutes.js';
import clinicRoutes from './routes/clinicRoutes.js';
import specialtyRoutes from "./routes/specialtyRoutes.js";
import searchRoutes from "./routes/searchRoutes.js";
import reviewRoutes from './routes/reviewRoutes.js';
import bookingRoutes from './routes/bookingRoutes.js';
import appointmentRoutes from './routes/appointmentRoutes.js';
import paymentRoute from "./routes/paymentRoutes.js";
import notificationRoute from "./routes/notificationRoutes.js";

const app = express();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 2. THÊM DÒNG NÀY: Tạo HTTP Server bọc quanh Express App
const server = http.createServer(app); 

// 3. THÊM ĐOẠN NÀY: Khởi tạo Socket.io Server liên kết với HTTP Server
const io = new Server(server, {
    cors: {
        origin: '*', // Cho phép mọi nguồn kết nối (Cấu hình lại theo tên miền Frontend khi deploy)
        methods: ["GET", "POST"]
    }
});

// 4. THÊM ĐOẠN NÀY: Quản lý danh sách người dùng online
const onlineUsers = new Map(); // Lưu cặp key-value: [Ma_nguoi_dung, socket.id]

io.on('connection', (socket) => {
    console.log(`[Socket] Thiết lập kết nối mới: ${socket.id}`);

    // Lắng nghe sự kiện khi Client đăng ký danh tính (sau khi đăng nhập)
    socket.on('register_user', (maNguoiDung) => {
        onlineUsers.set(String(maNguoiDung), socket.id);
        console.log(`[Socket] Người dùng ${maNguoiDung} đang ONLINE với socketID: ${socket.id}`);
    });

    // Lắng nghe khi Client chủ động ngắt kết nối (tắt tab hoặc logout)
    socket.on('disconnect', () => {
        for (let [maNguoiDung, socketId] of onlineUsers.entries()) {
            if (socketId === socket.id) {
                onlineUsers.delete(maNguoiDung);
                console.log(`[Socket] Người dùng ${maNguoiDung} đã OFFLINE`);
                break;
            }
        }
    });
});

// 5. THÊM ĐOẠN NÀY: Đính kèm `io` và `onlineUsers` vào Express App 
// Để có thể gọi lại ở bất kỳ file Router/Controller nào
app.set('io', io);
app.set('onlineUsers', onlineUsers);

app.use(bodyParser.json());
// THÊM DÒNG NÀY: Để Node.js đọc được dữ liệu từ Form HTML gửi lên
app.use(express.urlencoded({ extended: true })); 
app.use(cors({ origin: '*' }));

app.use(fileUpload({
    limits: { fileSize: 5 * 1024 * 1024 }, // Giới hạn ảnh tối đa 5MB
    createParentPath: true, // Tự động tạo thư mục 'uploads' nếu nó chưa tồn tại
    abortOnLimit: true // Báo lỗi ngay nếu file quá lớn
}));

//Routes
app.get('/',(req,res) => {
    res.json({message: "Server API running"});
});
app.use('/api/admin', adminRoutes);
app.use('/api/auth', userRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/record', healthRecordRoutes);
app.use('/api/doctors', doctorRoutes);
app.use('/api/clinics', clinicRoutes);
app.use('/api/specialty', specialtyRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/payment', paymentRoute);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/notification', notificationRoute);
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

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
// 6. SỬA DÒNG NÀY: Đổi từ app.listen sang server.listen
server.listen(PORT, ()=>{
    console.log(`Server running on port ${PORT}`);
});

export default app;