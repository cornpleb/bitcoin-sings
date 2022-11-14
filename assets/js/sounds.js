import { Howl, Howler } from '../vendor/howler'


export var Sounds = {
  activated: false,
  howlTx: null,
  howlBlock: null,

  toggle: function () {
    if (this.activated) {
      return this.activated = false
    }
    else {
      return this.activated = true
    }
  },

  playTx: function (name) {
    if (this.activated) {
      if (this.howlTx != null) {
        this.howlTx.stop()
      }

      this.howlTx = new Howl({
        src: ['/assets/sounds/guitar.wav'],
        html5: true
      })

      this.howlTx.play()
    }
  },

  playBlock: function (name) {
    if (this.activated) {
      if (this.howlBlock != null) {
        this.howlBlock.stop()
      }

      this.howlBlock = new Howl({
        src: ['/assets/sounds/mix.mp3'],
        html5: true
      })

      this.howlBlock.play()
    }
  }
}
