import net.http
import regex
import ui
import clipboard
import os

const (
	win_width   = 230
	win_height  = 100
)

[heap]
struct State {
mut:
	urlinput string
	cssvalue  string
	window     &ui.Window = unsafe { nil }
	is_error   bool
}

fn removeduplicatestrings(mut s []string) []string {
    if s.len < 1 {
        return s
    }

    s.sort(a > b)

    mut prev := 1
    for curr := 1; curr < s.len; curr++ {
        if s[curr-1] != s[curr] {
            s[prev] = s[curr]
            prev++
        }
    }

    return s
}


fn main(){

	mut app := &State{}

	window := ui.window(
		width: win_width
		height: win_height
		title: 'V - CSS SCRAPER'
		children: [
			ui.row(
				margin: ui.Margin{10, 10, 10, 10}
				widths: [200.0, ui.stretch]
				spacing: 30
				children: [
					ui.column(
						spacing: 13
						children: [
							ui.textbox(
								width: 200
								placeholder: 'Url'
								text: &app.urlinput
								is_focused: true
							),
							ui.button(
								text: 'Scrape css & copy'
								on_click: app.check
							),
						]
					),
				]
			),
		]
	)
	
	app.window = window
	ui.run(window)
}

fn (mut app State) check(b &ui.Button) {

	url := app.urlinput
	res := http.get(url)or {
		if os.user_os() == "windows" {
			os.execute("msg * Please enter a valid and accessible url.")
		}
		println("Please enter a valid and accessible url.")
		return
	}
	
	htmlresult := res.body
	tabhtmlresult := htmlresult.split("")


	mut tempstyleflag := ""
	mut tempendstyleflag := ""

	mut allcss := ""
	for carac in tabhtmlresult {

		//detect start
		match tempstyleflag {

			"" {
				if carac == "<" {
					tempstyleflag = "<"
				}else{
					tempstyleflag = ""
				}
			}

			"<" {
				if carac == "s" {
					tempstyleflag = "<s"
				}else{
					tempstyleflag = ""
				}
			}

			"<s" {
				if carac == "t" {
					tempstyleflag = "<st"
				}else{
					tempstyleflag = ""
				}
			}

			"<st" {
				if carac == "y" {
					tempstyleflag = "<sty"
				}else{
					tempstyleflag = ""
				}
			}

			"<sty" {
				if carac == "l" {
					tempstyleflag = "<styl"
				}else{
					tempstyleflag = ""
				}
			}

			"<styl" {
				if carac == "e" {
					tempstyleflag = "<style"
				}else{
					tempstyleflag = ""
				}
			}

			"<style" {
				if carac == ">" {
					tempstyleflag = "<style>"
				}
			}

			"<style>" {
				allcss = allcss + carac
			}

			else {
				tempstyleflag = ""
			}
		}


		//detect end
		match tempendstyleflag {

			"" {
				if carac == "<" {
					tempendstyleflag = "<"
				}else{
					tempendstyleflag = ""
				}
			}

			"<" {
				if carac == "/" {
					tempendstyleflag = "</"
				}else{
					tempendstyleflag = ""
				}
			}

			"</" {
				if carac == "s" {
					tempendstyleflag = "</s"
				}else{
					tempendstyleflag = ""
				}
			}

			"</s" {
				if carac == "t" {
					tempendstyleflag = "</st"
				}else{
					tempendstyleflag = ""
				}
			}

			"</st" {
				if carac == "y" {
					tempendstyleflag = "</sty"
				}else{
					tempendstyleflag = ""
				}
			}

			"</sty" {
				if carac == "l" {
					tempendstyleflag = "</styl"
				}else{
					tempendstyleflag = ""
				}
			}

			"</styl" {
				if carac == "e" {
					tempendstyleflag = "</style>"
				}
			}

			"</style>" {
				tempendstyleflag = ""
				tempstyleflag = ""
			}

			else {
				tempendstyleflag = ""
			}
		}


    }

	mut url_regex := regex.regex_opt("<link(?:(?!\bhref=)[^>])*>") or { panic(err) }
	mut matches := url_regex.find_all_str(htmlresult)
	matches = removeduplicatestrings(mut matches)
	for m in matches {
		mut decouperef := ""
		if m.contains("href='") {
			decouperef 		= m.split("href='")[1]
			decouperef 		= decouperef.split("'")[0]
		}else if m.contains("href=\"") {
			decouperef 		= m.split("href=\"")[1]
			decouperef 		= decouperef.split("\"")[0]
			
		}

		if decouperef.contains(".css"){
			
			if decouperef.contains("http"){
				rescss := http.get(decouperef) or {
					if os.user_os() == "windows" {
						os.execute("msg * Error on scraping url : " + decouperef +".")
					}
					println("Error on scraping url : " + decouperef +".")

					return
				}
				htmlresultcss := rescss.body
				allcss = allcss + htmlresultcss
				println("link : " + decouperef)
			}else{
				mut urlroot := url
				if urlroot.contains("://"){
					urlroot = urlroot.split("://")[1]
					if urlroot.contains("/") {
						urlroot = urlroot.split("/")[0]
					}
				} else {
					if urlroot.contains("/") {
						urlroot = urlroot.split("/")[0]
					}
				}
				
				println("link : " + "https://" + urlroot + decouperef)
				rescss := http.get("https://" + urlroot + decouperef)or {
					if os.user_os() == "windows" {
						os.execute("msg * Error on scraping url : " + "https://" + urlroot + decouperef +".")
					}
					println("Error on scraping url : " + "https://" + urlroot + decouperef +".")
					return
				}
				htmlresultcss := rescss.body
				allcss = allcss + htmlresultcss
			}
		}
	}

	allcss = allcss.replace("</style>", "")
	app.cssvalue = allcss

	mut c := clipboard.new()
	c.copy(app.cssvalue)
	$if windows {
		os.execute("msg * the css has been copied to your clipboard")
	}
	println("he css has been copied to your clipboard")

}