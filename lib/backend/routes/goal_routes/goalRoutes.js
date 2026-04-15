import express from 'express';
import { 
  addGoal, 
  getGoals,
  deleteGoal, 
  depositToGoal, 
  withdrawFromGoal,
  getGoalById,
  updateGoal
} from '../../controllers/goal_controllers/goalController.js';

const router = express.Router();

// Add a new goal
router.post('/addGoal', addGoal);

// Get all goals for a user
router.get('/getGoals/:userId', getGoals);

// Get a specific goal by ID
router.get('/getGoal/:goalId', getGoalById);

// Delete a goal
router.delete('/deleteGoal/:goalId', deleteGoal);

// Deposit money to a goal
router.post('/deposit/:goalId', depositToGoal);

// Withdraw money from a goal
router.post('/withdraw/:goalId', withdrawFromGoal);

// Update a goal
router.put('/updateGoal/:goalId', updateGoal);

export default router;