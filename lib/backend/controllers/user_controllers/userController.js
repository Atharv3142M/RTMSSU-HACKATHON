import Users from "../../models/userModel.js";
import mongoose from "mongoose";
import axios from "axios";

// Add a new user
export const addUser = async (req, res) => {
  try {
    const { userName, email } = req.body;

    console.log(req.body);

    if (userName === "" || email === "") {
      return res.status(400).json({ message: "All fields are required" });
    }

    const userExists = await Users.findOne({ email });
    if (userExists) {
      return res.status(400).json({ message: "User already exists" });
    }
    const user = new Users({ userName, email, password: req.body.password || "" });

    // Check if the email is blocked
    const blockedUser = await Users.findOne({ email, isBlocked: true });
    if (blockedUser) {
      return res.status(403).json({ message: "This email has been blocked by administrator" });
    }
    const userData = await user.save();

   

    //call n8n web hook
    try {
      await axios.post(
        "https://dhruv-chotai-10.app.n8n.cloud/webhook-test/user-added",
        {
          userName,
          email,
          _id: user._id,
        }
      );
      console.log("Webhook triggered successfully");
    } catch (webhookErr) {
      console.error("Failed to call n8n webhook:", webhookErr.message);
    }

    res.status(201).json({ message: "User created successfully", userData });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all users
export const getAllUsers = async (req, res) => {
  try {
    const users = await Users.find({}, "-password"); // Exclude password
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update a user
export const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    console.log('Update request for user ID:', id);
    console.log('Update data:', updates);

    // Validate the MongoDB ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: "Invalid user ID format" });
    }

    const user = await Users.findById(id);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Validate input data
    if (updates.userName === '') {
      return res.status(400).json({ message: "Username cannot be empty" });
    }

    if (updates.email && updates.email !== user.email) {
      // Check if email is unique if it's being changed
      const existingUserWithEmail = await Users.findOne({ email: updates.email, _id: { $ne: id } });
      if (existingUserWithEmail) {
        return res.status(400).json({ message: "Email already in use by another account" });
      }
    }

    // Allow updating userName, email, isBlocked, but not password (separate endpoint for that)
    const allowedUpdates = ['userName', 'email', 'isBlocked'];
    const updateData = {};

    for (const key of Object.keys(updates)) {
      if (allowedUpdates.includes(key)) {
        updateData[key] = updates[key];
      }
    }

    console.log('Final update data to apply:', updateData);

    const updatedUser = await Users.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    ).select('-password');

    console.log('Updated user:', updatedUser);

    if (!updatedUser) {
      return res.status(404).json({ message: "User update failed" });
    }

    res.status(200).json({
      message: "User updated successfully",
      user: updatedUser
    });
  } catch (error) {
    console.error("Error updating user:", error);
    res.status(500).json({ message: error.message });
  }
};

// Delete a specific user by ID
export const deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await Users.findByIdAndDelete(id);
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }
    // Cascade delete: Remove all transactions for this user
    const Transactions = (await import("../../models/transactionModel.js"))
      .default;
    const result = await Transactions.deleteMany({
      userId: new mongoose.Types.ObjectId(id),
    });
    console.log(`Deleted ${result.deletedCount} transactions for user ${id}`);
    res
      .status(200)
      .json({
        message: `User and their ${result.deletedCount} transactions deleted successfully`,
      });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Check if an email is blocked
export const checkBlocked = async (req, res) => {
  try {
    const { email } = req.query;
    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }

    const blockedUser = await Users.findOne({ email, isBlocked: true });
    res.status(200).json({
      email,
      isBlocked: !!blockedUser
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get user by email
export const getUserByEmail = async (req, res) => {
  try {
    const { email } = req.query;

    if (!email) {
      return res.status(400).json({ message: "Email parameter is required" });
    }

    const user = await Users.findOne({ email }, "-password"); // Exclude password
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json({ user });
  } catch (error) {
    console.error("Error in getUserByEmail:", error);
    res.status(500).json({ message: error.message });
  }
};
