import { Howl, Howler } from '../vendor/howler'


export var Sounds = {

  play: function () {

    var sound = new Howl({
      src: ['/assets/sounds/flute.wav'],
      html5: true
    })

    sound.play()
  }
}
