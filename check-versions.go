///usr/bin/env true; exec /usr/bin/env go run "$0" "$@"

package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"text/tabwriter"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

func init() {
	log.SetFlags(0)
}

func writeRelease(w io.Writer, owner, name, tag, url string) (int, error) {
	return fmt.Fprintf(w, "%s/%s\t%s\t%s\n", owner, name, tag, url)
}

func main() {
	token := flag.String("token", "", "Github token to use")
	flag.Parse()

	ctx := context.Background()

	var tc *http.Client
	if *token != "" {
		tc = oauth2.NewClient(ctx, oauth2.StaticTokenSource(&oauth2.Token{
			AccessToken: *token,
		}))
	}
	cl := github.NewClient(tc)

	w := tabwriter.NewWriter(os.Stdout, 0, 8, 0, '\t', 0)
	fmt.Fprintln(w, "Repository", "\tVersion", "\tRelease page")

	for _, repo := range []struct {
		owner, name string
	}{
		{"golang", "go"},
		{"grpc-ecosystem", "grpc-gateway"},
		{"grpc", "grpc"},
		{"protobuf-c", "protobuf-c"},
		{"pseudomuto", "protoc-gen-doc"},
		{"TheThingsIndustries", "protoc-gen-fieldmask"},
		{"golang", "protobuf"},
		{"gogo", "protobuf"},
		{"TheThingsIndustries", "protoc-gen-gogottn"},
		{"envoyproxy", "protoc-gen-validate"},
		{"upx", "upx"},
	} {
		tag := "n/a"
		url := "n/a"

		rel, _, err := cl.Repositories.GetLatestRelease(ctx, repo.owner, repo.name)
		if err != nil {
			log.Printf("Failed to query github API for latest release of `%s/%s`: %s, trying tags...", repo.owner, repo.name, err)
			tags, _, err := cl.Repositories.ListTags(ctx, repo.owner, repo.name, &github.ListOptions{
				PerPage: 1,
			})
			if err != nil {
				log.Printf("Failed to list tags of `%s/%s` on github: %s", repo.owner, repo.name, err)
			} else if len(tags) > 0 {
				tag = *tags[0].Name
			}
		} else {
			tag = *rel.TagName
			url = *rel.HTMLURL
		}

		if _, err := writeRelease(w, repo.owner, repo.name, tag, url); err != nil {
			log.Printf("Failed to write release %s(%s) of `%s/%s`: %s", err, tag, *rel.HTMLURL, repo.owner, repo.name)
		}
	}
	if err := w.Flush(); err != nil {
		log.Fatal(err)
	}
}
