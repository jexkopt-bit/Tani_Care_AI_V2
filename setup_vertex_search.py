#!/usr/bin/env python3
"""
TaniCare AI — Vertex AI Search Data Store Setup Script
=======================================================
Run this ONCE after your first Cloud Run deployment to provision
the RAG data store and upload seed agricultural documents.

Usage:
    pip install google-cloud-discoveryengine
    python setup_vertex_search.py
"""

import os
import time
from google.cloud import discoveryengine_v1 as discoveryengine
from google.api_core.exceptions import AlreadyExists

PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT", "tani-care-ai")
LOCATION = "global"
DATA_STORE_ID = "tanicare-rag-datastore"
COLLECTION = "default_collection"


def create_data_store(client: discoveryengine.DataStoreServiceClient) -> str:
    """Creates the Vertex AI Search data store for TaniCare RAG."""
    parent = f"projects/{PROJECT_ID}/locations/{LOCATION}/collections/{COLLECTION}"
    data_store = discoveryengine.DataStore(
        display_name="TaniCare Agricultural Knowledge Base",
        industry_vertical=discoveryengine.IndustryVertical.GENERIC,
        content_config=discoveryengine.DataStore.ContentConfig.CONTENT_REQUIRED,
        solution_types=[discoveryengine.SolutionType.SOLUTION_TYPE_SEARCH],
    )
    try:
        operation = client.create_data_store(
            parent=parent,
            data_store=data_store,
            data_store_id=DATA_STORE_ID,
        )
        print(f"[OK] Creating data store '{DATA_STORE_ID}'...")
        result = operation.result(timeout=120)
        print(f"[OK] Data store created: {result.name}")
        return result.name
    except AlreadyExists:
        print(f"[INFO] Data store '{DATA_STORE_ID}' already exists — skipping creation.")
        return f"{parent}/dataStores/{DATA_STORE_ID}"


def import_documents(
    doc_client: discoveryengine.DocumentServiceClient,
    data_store_name: str,
) -> None:
    """Imports seed RAG documents from the rag_docs/ directory."""
    branch = f"{data_store_name}/branches/default_branch"

    # Read all seed documents
    docs_dir = os.path.join(os.path.dirname(__file__), "rag_docs")
    if not os.path.isdir(docs_dir):
        print("[!] rag_docs/ directory not found — skipping document import.")
        return

    documents = []
    for i, filename in enumerate(os.listdir(docs_dir)):
        if not filename.endswith(".txt"):
            continue
        filepath = os.path.join(docs_dir, filename)
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        doc_id = filename.replace(".txt", "").replace(" ", "_")
        documents.append(
            discoveryengine.Document(
                id=doc_id,
                content=discoveryengine.Document.Content(
                    raw_bytes=content.encode("utf-8"),
                    mime_type="text/plain",
                ),
                json_data='{"source": "' + filename + '", "language": "ms"}',
            )
        )
        print(f"[OK] Prepared: {filename} ({len(content)} chars)")

    if not documents:
        print("[!] No .txt files found in rag_docs/ — nothing to import.")
        return

    # Batch import
    request = discoveryengine.ImportDocumentsRequest(
        parent=branch,
        inline_source=discoveryengine.ImportDocumentsRequest.InlineSource(
            documents=documents
        ),
        reconciliation_mode=discoveryengine.ImportDocumentsRequest.ReconciliationMode.INCREMENTAL,
    )
    operation = doc_client.import_documents(request=request)
    print(f"\n[OK] Importing {len(documents)} documents into Vertex AI Search...")
    result = operation.result(timeout=300)
    print(f"[OK] Import complete! {result}")


def main():
    print("=" * 60)
    print("TaniCare AI — Vertex AI Search Setup")
    print(f"Project : {PROJECT_ID}")
    print(f"Location: {LOCATION}")
    print(f"Store ID: {DATA_STORE_ID}")
    print("=" * 60)

    # Step 1: Create data store
    ds_client = discoveryengine.DataStoreServiceClient()
    data_store_name = create_data_store(ds_client)
    time.sleep(5)  # Brief wait for provisioning

    # Step 2: Import RAG seed documents
    doc_client = discoveryengine.DocumentServiceClient()
    import_documents(doc_client, data_store_name)

    print("\n" + "=" * 60)
    print("✅ Setup complete!")
    print(f"   Data Store ID : {DATA_STORE_ID}")
    print(f"   Project       : {PROJECT_ID}")
    print("   Your backend will now use this store for grounded RAG.")
    print("=" * 60)


if __name__ == "__main__":
    main()
