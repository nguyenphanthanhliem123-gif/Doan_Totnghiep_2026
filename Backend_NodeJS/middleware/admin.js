export default function admin(req,res,next){
    if(!req.Ma_nguoi_dung || !(req.Phan_quyen === 'Admin')){
        return res.status(403).json({message: 'Admin privileges required'});
    }
    next();
};