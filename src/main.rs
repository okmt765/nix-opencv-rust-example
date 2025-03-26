use anyhow::{bail, Result};
use opencv::{core, highgui, prelude::*, videoio};

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 2 {
        bail!("USAGE: nix-opencv-rust-example <PATH>");
    }

    let path = &args[1];
    let mut cap = match path.parse() {
        Ok(index) => videoio::VideoCapture::new(index, videoio::CAP_ANY)?,
        Err(_) => videoio::VideoCapture::from_file(path, videoio::CAP_ANY)?,
    };

    if !videoio::VideoCapture::is_opened(&cap)? {
        bail!("Failed to open VideoCapture.");
    }

    let mut img = core::Mat::default();
    loop {
        if !cap.read(&mut img)? {
            break;
        }
        dbg!(&img);

        let _ = highgui::imshow("image", &img);
        let _ = highgui::wait_key(1);
    }

    Ok(())
}
