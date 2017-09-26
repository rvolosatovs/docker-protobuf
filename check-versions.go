///usr/bin/env true; exec /usr/bin/env go run "$0" "$@"

package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"text/tabwriter"

	"github.com/google/go-github/github"
)

func main() {
	w := tabwriter.NewWriter(os.Stdout, 0, 8, 0, '\t', 0)
	fmt.Fprintln(w, "Repository", "\tVersion",  "\tRelease page")
	for owner, repos := range map[string][]string{
		"grpc":             {"grpc", "grpc-java", "grpc-swift"},
		"grpc-ecosystem":   {"grpc-gateway"},
		"protobuf-c":       {"protobuf-c"},
		"TheThingsNetwork": {"ttn"},
	} {
		for _, repo := range repos {
			rel, _, err := github.NewClient(nil).Repositories.GetLatestRelease(context.Background(), owner, repo)
			if err != nil {
				log.Fatal(err)
			}
			fmt.Fprintf(w, "%s/%s\t%s\t%s\n", owner, repo, *rel.TagName,  *rel.HTMLURL)
		}
	}
	if err := w.Flush(); err != nil {
		log.Fatal(err)
	}
}
