//Factory Pattern
abstract class Exercise{
  String logActivity();
}

class Walk implements Exercise {
  @override
  String logActivity() {
    return "Walk Successfully Logged";
  }
}


class Run implements Exercise {
  @override
  String logActivity() {
    return "Run Successfully Logged";
  }
}

class Fetch implements Exercise {
  @override
  String logActivity() {
    return "Fetch Successfully Logged";
  }
}

abstract class ExerciseFactory{
  Exercise createExercise();
}

class WalkFactory implements ExerciseFactory {
  @override
  Exercise createExercise() {
    return Walk();
  }
}

class RunFactory implements ExerciseFactory {
  @override
  Exercise createExercise() {
    return Run();
  }
}

class FetchFactory implements ExerciseFactory {
  @override
  Exercise createExercise() {
    return Fetch();
  }
}

//Main tester works
void main() {
  //Factory Creation
  ExerciseFactory walkFactory = WalkFactory();
  ExerciseFactory runFactory = RunFactory();
  ExerciseFactory fetchFactory = FetchFactory();

  //Use factories to create exercises
  Exercise walk = walkFactory.createExercise();
  Exercise run = runFactory.createExercise();
  Exercise fetch = fetchFactory.createExercise();

  //Log activities
  print(walk.logActivity());
  print(run.logActivity());
  print(fetch.logActivity());
}