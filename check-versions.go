///usr/bin/env true; exec /usr/bin/env go run "$0" "$@"

package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"text/tabwriter"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

func main() {
	token := flag.String("token", "", "Github token to use")
	flag.Parse()

	ctx := context.Background()

	var tc *http.Client
	if token != nil && *token != "" {
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: *token},
		)
		tc = oauth2.NewClient(ctx, ts)
	}
	cl := github.NewClient(tc)

	w := tabwriter.NewWriter(os.Stdout, 0, 8, 0, '\t', 0)
	fmt.Fprintln(w, "Repository", "\tVersion", "\tRelease page")
	for owner, repos := range map[string][]string{
		"grpc":             {"grpc", "grpc-java", "grpc-swift"},
		"grpc-ecosystem":   {"grpc-gateway"},
		"protobuf-c":       {"protobuf-c"},
		"ckaznocha":        {"protoc-gen-lint"},
		"pseudomuto":       {"protoc-gen-doc"},
		"TheThingsNetwork": {"ttn"},
		"Masterminds":      {"glide"},
		"stepancheg":       {"rust-protobuf", "grpc-rust"},
	} {
		for _, repo := range repos {
			rel, _, err := cl.Repositories.GetLatestRelease(ctx, owner, repo)
			if err != nil {
				if err, ok := err.(*github.ErrorResponse); ok && err.Response.StatusCode == http.StatusNotFound {
					tags, _, err := cl.Repositories.ListTags(ctx, owner, repo, nil)
					if err != nil {
						log.Fatal(err)
					}
					if len(tags) == 0 {
						log.Fatal("%s/%s repo has 0 tags", owner, repo)
					}
					fmt.Fprintf(w, "%s/%s\t%s\t%s\n", owner, repo, *tags[0].Name, "n/a")
					continue
				}
				log.Fatal(err)
			}
			fmt.Fprintf(w, "%s/%s\t%s\t%s\n", owner, repo, *rel.TagName, *rel.HTMLURL)
		}
	}
	if err := w.Flush(); err != nil {
		log.Fatal(err)
	}
}
