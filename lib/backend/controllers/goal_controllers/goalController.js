import Goal from "../../models/goalModel.js";

// Get all goals for a user
export const getGoals = async (req, res) => {
  try {
    const goals = await Goal.find({ userId: req.params.userId });
    res.status(200).json(goals);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Add a new goal
export const addGoal = async (req, res) => {
  try {
    const {
      userId,
      title,
      targetAmount,
      currentAmount,
      startDate,
      endDate,
      description,
    } = req.body;

    if (!userId || !title || !targetAmount || !startDate || !endDate) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const goal = new Goal({
      userId,
      title,
      targetAmount,
      currentAmount: currentAmount || 0,
      startDate,
      endDate,
      description,
    });

    await goal.save();
    res.status(201).json(goal);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Delete a goal by ID
export const deleteGoal = async (req, res) => {
  try {
    const { goalId } = req.params;
    const deletedGoal = await Goal.findByIdAndDelete(goalId);
    if (!deletedGoal) {
      return res.status(404).json({ message: "Goal not found" });
    }
    res.status(200).json({ message: "Goal deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Deposit money to a goal
export const depositToGoal = async (req, res) => {
  try {
    const { goalId } = req.params;
    const { amount } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({ message: "Invalid deposit amount" });
    }

    const goal = await Goal.findById(goalId);
    if (!goal) {
      return res.status(404).json({ message: "Goal not found" });
    }

    goal.currentAmount += parseFloat(amount);
    await goal.save();

    res.status(200).json({ 
      message: "Deposit successful", 
      goal 
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Withdraw money from a goal
export const withdrawFromGoal = async (req, res) => {
  try {
    const { goalId } = req.params;
    const { amount } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({ message: "Invalid withdrawal amount" });
    }

    const goal = await Goal.findById(goalId);
    if (!goal) {
      return res.status(404).json({ message: "Goal not found" });
    }

    if (goal.currentAmount < amount) {
      return res.status(400).json({ message: "Insufficient funds in this goal" });
    }

    goal.currentAmount -= parseFloat(amount);
    await goal.save();

    res.status(200).json({ 
      message: "Withdrawal successful", 
      goal 
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update a goal
export const updateGoal = async (req, res) => {
  try {
    const { goalId } = req.params;
    const {
      title,
      targetAmount,
      startDate,
      endDate,
      description,
    } = req.body;

    // Validate required fields
    if (!title || !targetAmount || !startDate || !endDate) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    // Find the goal
    const goal = await Goal.findById(goalId);
    if (!goal) {
      return res.status(404).json({ message: "Goal not found" });
    }

    // Update goal fields
    goal.title = title;
    goal.targetAmount = targetAmount;
    goal.startDate = startDate;
    goal.endDate = endDate;
    goal.description = description;

    // Save the updated goal
    await goal.save();
    
    res.status(200).json(goal);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get a single goal by ID
export const getGoalById = async (req, res) => {
  try {
    const { goalId } = req.params;
    const goal = await Goal.findById(goalId);
    
    if (!goal) {
      return res.status(404).json({ message: "Goal not found" });
    }
    
    res.status(200).json(goal);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};