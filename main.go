package main

import (
	"crypto/tls"
	"flag"
	"fmt"
	"github.com/JackDanger/collectlinks"
	"net/http"
	"net/url"
	"os"
	"strings"
)

func usage() {
	fmt.Fprintf(os.Stderr, "usage: crawl <URI>\n")
	flag.PrintDefaults()
	os.Exit(2)
}

func main() {

	flag.Usage = usage
	flag.Parse()

	args := flag.Args()

	if len(args) < 1 {
		fmt.Println("Please specify start page")
		os.Exit(1)
	}

	queue := make(chan string)
	filteredQueue := make(chan string)
	f, err := os.Create("/tmp/dat2")
	check(err)

	defer f.Close()

	go func() { queue <- args[0] }()
	go filterQueue(queue, filteredQueue)

	done := make(chan bool)

	for i := 0; i < 5; i++ {
		go func() {
			for uri := range filteredQueue {
				enqueue(uri, queue, f)
			}
			done <- true
		}()
	}
	<-done
}

func check(e error) {
	if e != nil {
		panic(e)
	}
}

func filterQueue(in chan string, out chan string) {
	var seen = make(map[string]bool)
	for val := range in {
		if strings.Contains(val, "www.") {
			if !seen[val] {
				seen[val] = true
				out <- val
			}
		}
	}
}

func enqueue(uri string, queue chan string, f *os.File) {

	fmt.Println("fetching", uri)
	f.WriteString(fmt.Sprintf("%s\n", uri))
	f.Sync()
	transport := &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
		},
	}
	client := http.Client{Transport: transport}
	resp, err := client.Get(uri)
	if err != nil {
		return
	}
	defer resp.Body.Close()

	links := collectlinks.All(resp.Body)

	for _, link := range links {
		if !strings.Contains(link, "www.") {
			absolute := fixURL(link, uri)
			if uri != "" {
				go func() { queue <- absolute }()
			}
		}
	}
}

func fixURL(href, base string) string {
	uri, err := url.Parse(href)
	if err != nil {
		return ""
	}
	baseURL, err := url.Parse(base)
	if err != nil {
		return ""
	}
	uri = baseURL.ResolveReference(uri)
	return uri.String()
}
