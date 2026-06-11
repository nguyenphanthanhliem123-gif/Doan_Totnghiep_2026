import userModel from "../models/userModel.js";
import jsonwebtoken from 'jsonwebtoken';
const { verify } = jsonwebtoken;
const JWT_SECRET = process.env.JWT_SECRET;

export default async function auth(req,res,next) {
    const authHeader = req.headers.authorization;

    if(!authHeader || !authHeader.startsWith('Bearer ')){
        return res.status(401).json({message: 'Authorization required'});
    }
    const token = authHeader.split(' ')[1];

    const { id } = verify(token, JWT_SECRET);
    if(!id) return res.status(401).json({message: 'Invalid or expired token'});
    const user = await userModel.findById(id);
    if(!user) return res.status(401).json({message: 'User not found'});

    req.Ma_nguoi_dung = id;
    req.username = user.Ten_nguoi_dung;
    req.phan_quyen = user.Phan_quyen;
    req.token = token;
    next();
}