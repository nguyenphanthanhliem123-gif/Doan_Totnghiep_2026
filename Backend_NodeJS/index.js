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
import jwt from 'jsonwebtoken';

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
import serviceRoutes from "./routes/serviceRoutes.js";

const app = express();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Tạo HTTP Server bọc quanh Express App
const server = http.createServer(app); 

app.use(cors({ origin: '*' }));
app.use(bodyParser.json());
app.use(express.urlencoded({ extended: true })); 
app.use(fileUpload({
    limits: { fileSize: 10 * 1024 * 1024 },
    createParentPath: true,
}));

// Khởi tạo Socket.io Server liên kết với HTTP Server
const io = new Server(server, {
    cors: {
        origin: '*', // Cho phép mọi nguồn kết nối (Cấu hình lại theo tên miền Frontend khi deploy)
        methods: ["GET", "POST"]
    }
});

io.use((socket, next) => {
    // 🌟 LẤY TOKEN từ gói handshake.auth mà Flutter gửi lên
    const token = socket.handshake.auth?.token;

    if (!token) {
        return next(new Error("Authentication error: Không tìm thấy Token"));
    }

    try {
        let decoded;
        try {
            // Thử giải mã bằng khóa của Bệnh nhân / Bác sĩ
            decoded = jwt.verify(token, process.env.JWT_SECRET);
            socket.role = 'user'; // Đánh dấu đây là user thường
        } catch (err1) {
            // Nếu lỗi, thử giải mã bằng khóa của Admin
            decoded = jwt.verify(token, process.env.ADMIN_JWT_SECRET || "AdminSecretKey123");
            socket.role = 'admin'; // Đánh dấu đây là admin
            
            // Cập nhật room đặc biệt cho admin để sau này dễ gửi thông báo tập thể
            socket.join('admin_room'); 
        }
        
        socket.userId = decoded.id; 
        next(); 
    } catch (err2) {
        // Nếu cả 2 key đều giải mã thất bại
        return next(new Error("Authentication error: Token không hợp lệ hoặc hết hạn"));
    }
});

// Quản lý danh sách người dùng online
if (!global.onlineUsers) {
    global.onlineUsers = new Map();
}

io.on('connection', (socket) => {
    // Lấy userId an toàn đã được xác thực từ middleware
    const currentUser = String(socket.userId);
    
    console.log(`[Socket] Thiết lập kết nối mới: ${socket.id}`);

    // 🌟 ĐĂNG KÝ LUÔN: Không cần đợi client emit 'register_user' nữa!
    global.onlineUsers.set(currentUser, socket.id);
    console.log(`[Socket] Người dùng ${currentUser} đang ONLINE với socketID: ${socket.id}`);

    // Lắng nghe khi Client ngắt kết nối (tắt app, mất mạng hoặc logout)
    socket.on('disconnect', () => {
        // 🌟 XÓA TRỰC TIẾP: Chỉ mất 1 dòng, không cần chạy vòng lặp quét mảng
        global.onlineUsers.delete(currentUser);
        console.log(`[Socket] Người dùng ${currentUser} đã OFFLINE`);
    });
});

// 5. THÊM ĐOẠN NÀY: Đính kèm `io` và `onlineUsers` vào Express App 
// Để có thể gọi lại ở bất kỳ file Router/Controller nào
app.set('io', io);
app.set('onlineUsers', onlineUsers);

app.use(bodyParser.json());
// THÊM DÒNG NÀY: Để Node.js đọc được dữ liệu từ Form HTML gửi lên
app.use(express.urlencoded({ extended: true })); 

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
app.use('/api/services', serviceRoutes);
app.use('/uploads', (req, res, next) => {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    res.header("Cross-Origin-Resource-Policy", "cross-origin"); // Quan trọng cho ảnh
    next();
}, express.static(path.join(__dirname, 'uploads')));

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