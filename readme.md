### Wake
A little mobile application that extend base alarm feature with hard to skip alarm capability

##### How it work?
1- start running the current alarm  
2- show skip problem to solve  
3- while problem !is solved then continue running

###### TODO
- [x] simple alarm using [AlarmManager](https://developer.android.com/reference/kotlin/android/app/AlarmManager)
- [x] ios support using [AlarmKit](https://developer.apple.com/documentation/alarmkit) — see [wake/ios/AlarmKit.md](wake/ios/AlarmKit.md)
- [ ] skip prevention
  - [ ] android
  - [x] iOS — (used re-alarm strategy to fire alarm again again until quiz solved ios dont allow hard block)