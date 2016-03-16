import Player from "./player"

let Video = {

  init(socket, element){ if(!element){ return }
    let playerId = element.getAttribute("data-player-id")
    let videoId  = element.getAttribute("data-id")
    socket.connect()
    Player.init(element.id, playerId, () => {

      // Runs after Player has loaded
      this.onReady(videoId, socket)
    })
  },

  // DOM variables for our Video player
  // msgContainer is for annotations
  // msgInput, postButton are both for creating a new annotation
  // vidChannel will be used to connect our ES6 client to the Phoenix VideoChannel
  // The topics, which in this case are the videos, will need an identifier. We
  // take the form (conventionally) videos: + videoId. This lets us send events
  // easily to others interested in the same topic
  onReady(videoId, socket){
    let msgContainer = document.getElementById("msg-container")
    let msgInput     = document.getElementById("msg-input")
    let postButton   = document.getElementById("msg-submit")
    let vidChannel   = document.getElementById("videos:" + videoId)
    // TODO join the vidChannel
  }
}
export default Video
