# VolumeButtonHandler
VolumeButtonHandler for iOS

A simple library inspired by https://github.com/jpsim/JPSVolumeButtonHandler but written in Swift instead.

This library handles the users up/down volume button presses.

Simply do this:

    @State private var volumeHandler = VolumeButtonHandler()
    volumeHandler.startHandler(disableSystemVolumeHandler: false)

    volumeHandler.upBlock = {
        viewModel.volume = volumeHandler.currentVolume
        debugPrint("Up block")
    }
    volumeHandler.downBlock = {
        viewModel.volume = volumeHandler.currentVolume
        debugPrint("Down block")
    }

Happy coding!
