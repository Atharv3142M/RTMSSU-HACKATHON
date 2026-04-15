import express from "express";
import { 
  addUser, 
  getAllUsers, 
  deleteUser, 
  updateUser, 
  checkBlocked,
  getUserByEmail
} from "../../controllers/user_controllers/userController.js";

const router = express.Router();

// Add a new user
router.post("/addUser", addUser);

// Get all users
router.get("/getAllUsers", getAllUsers);

// Get user by email
router.get("/getUserByEmail", getUserByEmail);

// Update a user
router.put("/updateUser/:id", updateUser);

// Delete a user
router.delete("/deleteUser/:id", deleteUser);

// Check if email is blocked
router.get("/checkBlocked", checkBlocked);

export default router;