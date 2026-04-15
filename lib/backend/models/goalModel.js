import mongoose from 'mongoose';

const goalSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  title: {
    type: String,
    required: true
  },  
  targetAmount: {
    type: Number,
    required: true
  },
  currentAmount: {
    type: Number,
    default: 0
  },
  startDate: {
    type: Date,
    required: true
  },
  createdAt: {
    type: Date, 
    default: Date.now
  },
  endDate: {
    type: Date,
    required: true
  },
  description: {
    type: String,
    default: "",
    required: false
  }
});

const Goal = mongoose.model('Goal',goalSchema);

export default Goal;