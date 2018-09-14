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
	for _, repo := range []struct {
		owner, name string
	}{
		{"apple", "swift"},
		{"ckaznocha", "protoc-gen-lint"},
		{"golang", "go"},
		{"grpc", "grpc"},
		{"grpc", "grpc-java"},
		{"grpc", "grpc-swift"},
		{"grpc-ecosystem", "grpc-gateway"},
		{"protobuf-c", "protobuf-c"},
		{"pseudomuto", "protoc-gen-doc"},
		{"rust-lang", "rust"},
		{"stepancheg", "grpc-rust"},
		{"stepancheg", "rust-protobuf"},
		{"TheThingsIndustries", "protoc-gen-gogottn"},
		{"TheThingsNetwork", "ttn"},
		{"upx", "upx"},
	} {
		rel, _, err := cl.Repositories.GetLatestRelease(ctx, repo.owner, repo.name)
		if err != nil {
			if err, ok := err.(*github.ErrorResponse); ok && err.Response.StatusCode == http.StatusNotFound {
				tags, _, err := cl.Repositories.ListTags(ctx, repo.owner, repo.name, nil)
				if err != nil {
					log.Fatal(err)
				}
				if len(tags) == 0 {
					log.Fatal("%s/%s repo has 0 tags", repo.owner, repo.name)
				}
				fmt.Fprintf(w, "%s/%s\t%s\t%s\n", repo.owner, repo.name, *tags[0].Name, "n/a")
				continue
			}
			log.Fatal(err)
		}
		fmt.Fprintf(w, "%s/%s\t%s\t%s\n", repo.owner, repo.name, *rel.TagName, *rel.HTMLURL)
	}
	if err := w.Flush(); err != nil {
		log.Fatal(err)
	}
}
